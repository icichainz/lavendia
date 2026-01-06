import csv
import io
from datetime import timedelta
from decimal import Decimal

from django.db.models import Count, Sum, Avg, F, Q
from django.db.models.functions import TruncDate, TruncHour, ExtractHour
from django.http import HttpResponse
from django.utils import timezone
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from apps.receipts.models import Receipt
from apps.users.models import User
from apps.laundromats.models import Laundromat
from .serializers import (
    OverviewSerializer,
    RevenueTrendSerializer,
    StatusDistributionSerializer,
    TopCustomerSerializer,
    StaffPerformanceSerializer,
    LaundromatComparisonSerializer,
    PeakHoursSerializer,
)

# PDF generation imports
try:
    from reportlab.lib import colors
    from reportlab.lib.pagesizes import letter, A4
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    from reportlab.lib.units import inch
    from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
    REPORTLAB_AVAILABLE = True
except ImportError:
    REPORTLAB_AVAILABLE = False


class AnalyticsViewSet(viewsets.ViewSet):
    """
    ViewSet for analytics endpoints.
    Staff can see analytics for their laundromat.
    Admin can see analytics for all laundromats.
    """
    permission_classes = [IsAuthenticated]

    def get_time_range_filter(self, time_range):
        """Get start and end datetime based on time range parameter"""
        now = timezone.now()

        if time_range == 'today':
            start = now.replace(hour=0, minute=0, second=0, microsecond=0)
        elif time_range == 'week':
            start = now - timedelta(days=7)
        elif time_range == 'month':
            start = now - timedelta(days=30)
        elif time_range == 'quarter':
            start = now - timedelta(days=90)
        elif time_range == 'year':
            start = now - timedelta(days=365)
        else:
            # Default to month
            start = now - timedelta(days=30)

        return start, now

    def get_base_queryset(self, request):
        """Apply role-based filtering to receipts queryset"""
        user = request.user
        queryset = Receipt.objects.all()

        if hasattr(user, 'is_customer') and user.is_customer:
            # Customers shouldn't access analytics
            return Receipt.objects.none()
        elif hasattr(user, 'is_staff_member') and user.is_staff_member and user.laundromat:
            # Staff can only see their laundromat's data
            return queryset.filter(laundromat=user.laundromat)

        # Admin sees all
        return queryset

    def check_analytics_permission(self, request):
        """Check if user has permission to view analytics"""
        user = request.user
        if hasattr(user, 'is_customer') and user.is_customer:
            return False
        return True

    @action(detail=False, methods=['get'])
    def overview(self, request):
        """
        Get analytics overview with key metrics.
        Query params: time_range (today|week|month|quarter|year)
        """
        if not self.check_analytics_permission(request):
            return Response(
                {'error': 'You do not have permission to view analytics'},
                status=status.HTTP_403_FORBIDDEN
            )

        time_range = request.query_params.get('time_range', 'month')
        start_date, end_date = self.get_time_range_filter(time_range)

        queryset = self.get_base_queryset(request).filter(
            created_at__gte=start_date,
            created_at__lte=end_date
        )

        # Calculate metrics
        total_orders = queryset.count()
        active_orders = queryset.filter(
            status__in=['pending', 'washing', 'drying', 'ready']
        ).count()
        completed_orders = queryset.filter(status='completed').count()
        cancelled_orders = queryset.filter(status='cancelled').count()

        # Revenue calculation
        revenue_data = queryset.exclude(status='cancelled').aggregate(
            total=Sum('price')
        )
        total_revenue = revenue_data['total'] or Decimal('0.00')

        # Average order value
        avg_order = queryset.exclude(status='cancelled').aggregate(
            avg=Avg('price')
        )
        average_order_value = avg_order['avg'] or Decimal('0.00')

        # Unique customers
        total_customers = queryset.values('customer').distinct().count()

        data = {
            'total_revenue': total_revenue,
            'total_orders': total_orders,
            'active_orders': active_orders,
            'completed_orders': completed_orders,
            'cancelled_orders': cancelled_orders,
            'total_customers': total_customers,
            'average_order_value': average_order_value,
            'time_range': time_range,
        }

        serializer = OverviewSerializer(data)
        return Response(serializer.data)

    @action(detail=False, methods=['get'], url_path='revenue-trend')
    def revenue_trend(self, request):
        """
        Get revenue trend over time for charting.
        Query params: time_range (today|week|month|quarter|year)
        """
        if not self.check_analytics_permission(request):
            return Response(
                {'error': 'You do not have permission to view analytics'},
                status=status.HTTP_403_FORBIDDEN
            )

        time_range = request.query_params.get('time_range', 'month')
        start_date, end_date = self.get_time_range_filter(time_range)

        queryset = self.get_base_queryset(request).filter(
            created_at__gte=start_date,
            created_at__lte=end_date
        ).exclude(status='cancelled')

        # Group by date and calculate revenue
        trends = queryset.annotate(
            date=TruncDate('created_at')
        ).values('date').annotate(
            revenue=Sum('price'),
            order_count=Count('id')
        ).order_by('date')

        # Convert to list and ensure all dates have entries
        trend_data = []
        for item in trends:
            trend_data.append({
                'date': item['date'],
                'revenue': item['revenue'] or Decimal('0.00'),
                'order_count': item['order_count'],
            })

        serializer = RevenueTrendSerializer(trend_data, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'], url_path='order-status-distribution')
    def order_status_distribution(self, request):
        """
        Get distribution of orders by status.
        Query params: time_range (today|week|month|quarter|year)
        """
        if not self.check_analytics_permission(request):
            return Response(
                {'error': 'You do not have permission to view analytics'},
                status=status.HTTP_403_FORBIDDEN
            )

        time_range = request.query_params.get('time_range', 'month')
        start_date, end_date = self.get_time_range_filter(time_range)

        queryset = self.get_base_queryset(request).filter(
            created_at__gte=start_date,
            created_at__lte=end_date
        )

        total_count = queryset.count()

        # Group by status
        distribution = queryset.values('status').annotate(
            count=Count('id')
        ).order_by('-count')

        # Calculate percentages
        distribution_data = []
        for item in distribution:
            percentage = (item['count'] / total_count * 100) if total_count > 0 else 0
            distribution_data.append({
                'status': item['status'],
                'count': item['count'],
                'percentage': round(percentage, 2),
            })

        serializer = StatusDistributionSerializer(distribution_data, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'], url_path='top-customers')
    def top_customers(self, request):
        """
        Get top customers by total spent.
        Query params: time_range, limit (default 10)
        """
        if not self.check_analytics_permission(request):
            return Response(
                {'error': 'You do not have permission to view analytics'},
                status=status.HTTP_403_FORBIDDEN
            )

        time_range = request.query_params.get('time_range', 'month')
        limit = int(request.query_params.get('limit', 10))
        start_date, end_date = self.get_time_range_filter(time_range)

        queryset = self.get_base_queryset(request).filter(
            created_at__gte=start_date,
            created_at__lte=end_date
        ).exclude(status='cancelled')

        # Group by customer
        top_customers = queryset.values(
            'customer__id',
            'customer__username',
            'customer__email',
            'customer__phone',
            'customer__first_name',
            'customer__last_name',
        ).annotate(
            order_count=Count('id'),
            total_spent=Sum('price')
        ).order_by('-total_spent')[:limit]

        # Format response
        customer_data = []
        for item in top_customers:
            name_parts = [
                item['customer__first_name'] or '',
                item['customer__last_name'] or ''
            ]
            customer_name = ' '.join(filter(None, name_parts)) or item['customer__username']

            customer_data.append({
                'customer_id': item['customer__id'],
                'customer_name': customer_name,
                'customer_email': item['customer__email'],
                'customer_phone': item['customer__phone'],
                'order_count': item['order_count'],
                'total_spent': item['total_spent'] or Decimal('0.00'),
            })

        serializer = TopCustomerSerializer(customer_data, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'], url_path='staff-performance')
    def staff_performance(self, request):
        """
        Get staff performance metrics.
        Query params: time_range
        """
        if not self.check_analytics_permission(request):
            return Response(
                {'error': 'You do not have permission to view analytics'},
                status=status.HTTP_403_FORBIDDEN
            )

        time_range = request.query_params.get('time_range', 'month')
        start_date, end_date = self.get_time_range_filter(time_range)

        queryset = self.get_base_queryset(request).filter(
            created_at__gte=start_date,
            created_at__lte=end_date,
            staff__isnull=False
        )

        # Group by staff
        staff_stats = queryset.values(
            'staff__id',
            'staff__username',
            'staff__first_name',
            'staff__last_name',
        ).annotate(
            order_count=Count('id'),
            completed_orders=Count('id', filter=Q(status='completed')),
            total_revenue=Sum('price', filter=~Q(status='cancelled')),
        ).order_by('-order_count')

        # Calculate average processing time for completed orders
        performance_data = []
        for item in staff_stats:
            # Get completed receipts with both dates set
            completed_receipts = queryset.filter(
                staff__id=item['staff__id'],
                status='completed',
                actual_pickup_date__isnull=False
            )

            # Calculate average processing time
            avg_hours = None
            if completed_receipts.exists():
                total_hours = 0
                count = 0
                for receipt in completed_receipts:
                    if receipt.actual_pickup_date and receipt.drop_off_date:
                        delta = receipt.actual_pickup_date - receipt.drop_off_date
                        total_hours += delta.total_seconds() / 3600
                        count += 1
                if count > 0:
                    avg_hours = round(total_hours / count, 2)

            name_parts = [
                item['staff__first_name'] or '',
                item['staff__last_name'] or ''
            ]
            staff_name = ' '.join(filter(None, name_parts)) or item['staff__username']

            performance_data.append({
                'staff_id': item['staff__id'],
                'staff_name': staff_name,
                'order_count': item['order_count'],
                'completed_orders': item['completed_orders'],
                'avg_processing_hours': avg_hours,
                'total_revenue': item['total_revenue'] or Decimal('0.00'),
            })

        serializer = StaffPerformanceSerializer(performance_data, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'], url_path='laundromat-comparison')
    def laundromat_comparison(self, request):
        """
        Compare all laundromats (admin only).
        Query params: time_range
        """
        user = request.user

        # Only admin can see laundromat comparison
        if not (hasattr(user, 'is_admin_user') and user.is_admin_user):
            return Response(
                {'error': 'Only admin users can view laundromat comparison'},
                status=status.HTTP_403_FORBIDDEN
            )

        time_range = request.query_params.get('time_range', 'month')
        start_date, end_date = self.get_time_range_filter(time_range)

        queryset = Receipt.objects.filter(
            created_at__gte=start_date,
            created_at__lte=end_date
        )

        # Group by laundromat
        laundromat_stats = queryset.values(
            'laundromat__id',
            'laundromat__name',
        ).annotate(
            order_count=Count('id'),
            revenue=Sum('price', filter=~Q(status='cancelled')),
            customer_count=Count('customer', distinct=True),
            active_orders=Count('id', filter=Q(
                status__in=['pending', 'washing', 'drying', 'ready']
            )),
        ).order_by('-revenue')

        # Format response
        comparison_data = []
        for item in laundromat_stats:
            avg_order_value = None
            if item['order_count'] > 0 and item['revenue']:
                avg_order_value = item['revenue'] / item['order_count']

            comparison_data.append({
                'laundromat_id': item['laundromat__id'],
                'laundromat_name': item['laundromat__name'],
                'revenue': item['revenue'] or Decimal('0.00'),
                'order_count': item['order_count'],
                'customer_count': item['customer_count'],
                'active_orders': item['active_orders'],
                'avg_order_value': avg_order_value,
            })

        serializer = LaundromatComparisonSerializer(comparison_data, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'], url_path='peak-hours')
    def peak_hours(self, request):
        """
        Analyze peak hours for orders.
        Query params: time_range
        """
        if not self.check_analytics_permission(request):
            return Response(
                {'error': 'You do not have permission to view analytics'},
                status=status.HTTP_403_FORBIDDEN
            )

        time_range = request.query_params.get('time_range', 'month')
        start_date, end_date = self.get_time_range_filter(time_range)

        queryset = self.get_base_queryset(request).filter(
            created_at__gte=start_date,
            created_at__lte=end_date
        )

        # Group by hour
        hourly_stats = queryset.annotate(
            hour=ExtractHour('created_at')
        ).values('hour').annotate(
            order_count=Count('id'),
            revenue=Sum('price', filter=~Q(status='cancelled'))
        ).order_by('hour')

        peak_data = []
        for item in hourly_stats:
            peak_data.append({
                'hour': item['hour'],
                'order_count': item['order_count'],
                'revenue': item['revenue'] or Decimal('0.00'),
            })

        serializer = PeakHoursSerializer(peak_data, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'], url_path='export/pdf')
    def export_pdf(self, request):
        """
        Export analytics report as PDF.
        Query params: time_range
        """
        if not self.check_analytics_permission(request):
            return Response(
                {'error': 'You do not have permission to export analytics'},
                status=status.HTTP_403_FORBIDDEN
            )

        if not REPORTLAB_AVAILABLE:
            return Response(
                {'error': 'PDF generation is not available. Please install reportlab.'},
                status=status.HTTP_503_SERVICE_UNAVAILABLE
            )

        time_range = request.query_params.get('time_range', 'month')
        start_date, end_date = self.get_time_range_filter(time_range)

        # Get analytics data
        queryset = self.get_base_queryset(request).filter(
            created_at__gte=start_date,
            created_at__lte=end_date
        )

        # Calculate metrics
        total_orders = queryset.count()
        completed_orders = queryset.filter(status='completed').count()
        revenue_data = queryset.exclude(status='cancelled').aggregate(total=Sum('price'))
        total_revenue = revenue_data['total'] or Decimal('0.00')
        total_customers = queryset.values('customer').distinct().count()

        # Create PDF
        buffer = io.BytesIO()
        doc = SimpleDocTemplate(buffer, pagesize=A4)
        elements = []
        styles = getSampleStyleSheet()

        # Title
        title_style = ParagraphStyle(
            'CustomTitle',
            parent=styles['Heading1'],
            fontSize=24,
            spaceAfter=30,
        )
        elements.append(Paragraph('Lavendia Analytics Report', title_style))

        # Time range
        elements.append(Paragraph(f'Time Range: {time_range.capitalize()}', styles['Normal']))
        elements.append(Paragraph(f'From: {start_date.strftime("%Y-%m-%d")} To: {end_date.strftime("%Y-%m-%d")}', styles['Normal']))
        elements.append(Spacer(1, 20))

        # Overview table
        elements.append(Paragraph('Overview', styles['Heading2']))
        overview_data = [
            ['Metric', 'Value'],
            ['Total Revenue', f'${total_revenue:.2f}'],
            ['Total Orders', str(total_orders)],
            ['Completed Orders', str(completed_orders)],
            ['Unique Customers', str(total_customers)],
        ]
        overview_table = Table(overview_data, colWidths=[3*inch, 2*inch])
        overview_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#6366F1')),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 12),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
            ('BACKGROUND', (0, 1), (-1, -1), colors.HexColor('#F3F4F6')),
            ('GRID', (0, 0), (-1, -1), 1, colors.HexColor('#E5E7EB')),
            ('FONTSIZE', (0, 1), (-1, -1), 10),
            ('TOPPADDING', (0, 1), (-1, -1), 8),
            ('BOTTOMPADDING', (0, 1), (-1, -1), 8),
        ]))
        elements.append(overview_table)
        elements.append(Spacer(1, 20))

        # Status distribution table
        elements.append(Paragraph('Order Status Distribution', styles['Heading2']))
        status_data = [['Status', 'Count', 'Percentage']]
        status_counts = queryset.values('status').annotate(count=Count('id')).order_by('-count')
        for item in status_counts:
            percentage = (item['count'] / total_orders * 100) if total_orders > 0 else 0
            status_data.append([
                item['status'].capitalize(),
                str(item['count']),
                f'{percentage:.1f}%'
            ])

        status_table = Table(status_data, colWidths=[2*inch, 1.5*inch, 1.5*inch])
        status_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#10B981')),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 12),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
            ('BACKGROUND', (0, 1), (-1, -1), colors.HexColor('#F3F4F6')),
            ('GRID', (0, 0), (-1, -1), 1, colors.HexColor('#E5E7EB')),
            ('FONTSIZE', (0, 1), (-1, -1), 10),
            ('TOPPADDING', (0, 1), (-1, -1), 8),
            ('BOTTOMPADDING', (0, 1), (-1, -1), 8),
        ]))
        elements.append(status_table)
        elements.append(Spacer(1, 20))

        # Footer
        elements.append(Spacer(1, 30))
        elements.append(Paragraph(
            f'Generated on {timezone.now().strftime("%Y-%m-%d %H:%M")} by Lavendia',
            styles['Normal']
        ))

        # Build PDF
        doc.build(elements)
        buffer.seek(0)

        # Create response
        response = HttpResponse(buffer, content_type='application/pdf')
        filename = f'lavendia_analytics_{time_range}_{timezone.now().strftime("%Y%m%d")}.pdf'
        response['Content-Disposition'] = f'attachment; filename="{filename}"'

        return response

    @action(detail=False, methods=['get'], url_path='export/csv')
    def export_csv(self, request):
        """
        Export detailed transaction data as CSV.
        Query params: time_range
        """
        if not self.check_analytics_permission(request):
            return Response(
                {'error': 'You do not have permission to export analytics'},
                status=status.HTTP_403_FORBIDDEN
            )

        time_range = request.query_params.get('time_range', 'month')
        start_date, end_date = self.get_time_range_filter(time_range)

        queryset = self.get_base_queryset(request).filter(
            created_at__gte=start_date,
            created_at__lte=end_date
        ).select_related('customer', 'staff', 'laundromat').order_by('-created_at')

        # Create CSV response
        response = HttpResponse(content_type='text/csv')
        filename = f'lavendia_transactions_{time_range}_{timezone.now().strftime("%Y%m%d")}.csv'
        response['Content-Disposition'] = f'attachment; filename="{filename}"'

        writer = csv.writer(response)

        # Write header
        writer.writerow([
            'Receipt Number',
            'Date',
            'Customer',
            'Customer Phone',
            'Laundromat',
            'Staff',
            'Status',
            'Items Count',
            'Items Description',
            'Price',
            'Drop Off Date',
            'Expected Pickup',
            'Actual Pickup',
            'Special Instructions'
        ])

        # Write data rows
        for receipt in queryset:
            customer_name = ''
            if receipt.customer:
                name_parts = [
                    receipt.customer.first_name or '',
                    receipt.customer.last_name or ''
                ]
                customer_name = ' '.join(filter(None, name_parts)) or receipt.customer.username

            staff_name = ''
            if receipt.staff:
                name_parts = [
                    receipt.staff.first_name or '',
                    receipt.staff.last_name or ''
                ]
                staff_name = ' '.join(filter(None, name_parts)) or receipt.staff.username

            writer.writerow([
                receipt.receipt_number,
                receipt.created_at.strftime('%Y-%m-%d %H:%M'),
                customer_name,
                receipt.customer.phone if receipt.customer else '',
                receipt.laundromat.name if receipt.laundromat else '',
                staff_name,
                receipt.status,
                receipt.items_count,
                receipt.items_description or '',
                str(receipt.price) if receipt.price else '0.00',
                receipt.drop_off_date.strftime('%Y-%m-%d %H:%M') if receipt.drop_off_date else '',
                receipt.expected_pickup_date.strftime('%Y-%m-%d %H:%M') if receipt.expected_pickup_date else '',
                receipt.actual_pickup_date.strftime('%Y-%m-%d %H:%M') if receipt.actual_pickup_date else '',
                receipt.special_instructions or ''
            ])

        return response
