// Analytics data models for the dashboard

class AnalyticsOverview {
  final double totalRevenue;
  final int totalOrders;
  final int activeOrders;
  final int completedOrders;
  final int cancelledOrders;
  final int totalCustomers;
  final double averageOrderValue;
  final String timeRange;

  AnalyticsOverview({
    required this.totalRevenue,
    required this.totalOrders,
    required this.activeOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.totalCustomers,
    required this.averageOrderValue,
    required this.timeRange,
  });

  factory AnalyticsOverview.fromJson(Map<String, dynamic> json) {
    return AnalyticsOverview(
      totalRevenue: double.tryParse(json['total_revenue'].toString()) ?? 0.0,
      totalOrders: json['total_orders'] ?? 0,
      activeOrders: json['active_orders'] ?? 0,
      completedOrders: json['completed_orders'] ?? 0,
      cancelledOrders: json['cancelled_orders'] ?? 0,
      totalCustomers: json['total_customers'] ?? 0,
      averageOrderValue: double.tryParse(json['average_order_value'].toString()) ?? 0.0,
      timeRange: json['time_range'] ?? 'month',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_revenue': totalRevenue,
      'total_orders': totalOrders,
      'active_orders': activeOrders,
      'completed_orders': completedOrders,
      'cancelled_orders': cancelledOrders,
      'total_customers': totalCustomers,
      'average_order_value': averageOrderValue,
      'time_range': timeRange,
    };
  }
}

class RevenueTrend {
  final DateTime date;
  final double revenue;
  final int orderCount;

  RevenueTrend({
    required this.date,
    required this.revenue,
    required this.orderCount,
  });

  factory RevenueTrend.fromJson(Map<String, dynamic> json) {
    return RevenueTrend(
      date: DateTime.parse(json['date']),
      revenue: double.tryParse(json['revenue'].toString()) ?? 0.0,
      orderCount: json['order_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String().split('T')[0],
      'revenue': revenue,
      'order_count': orderCount,
    };
  }
}

class StatusDistribution {
  final String status;
  final int count;
  final double percentage;

  StatusDistribution({
    required this.status,
    required this.count,
    required this.percentage,
  });

  factory StatusDistribution.fromJson(Map<String, dynamic> json) {
    return StatusDistribution(
      status: json['status'] ?? '',
      count: json['count'] ?? 0,
      percentage: double.tryParse(json['percentage'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'count': count,
      'percentage': percentage,
    };
  }
}

class TopCustomer {
  final int customerId;
  final String customerName;
  final String? customerEmail;
  final String? customerPhone;
  final int orderCount;
  final double totalSpent;

  TopCustomer({
    required this.customerId,
    required this.customerName,
    this.customerEmail,
    this.customerPhone,
    required this.orderCount,
    required this.totalSpent,
  });

  factory TopCustomer.fromJson(Map<String, dynamic> json) {
    return TopCustomer(
      customerId: json['customer_id'] ?? 0,
      customerName: json['customer_name'] ?? 'Unknown',
      customerEmail: json['customer_email'],
      customerPhone: json['customer_phone'],
      orderCount: json['order_count'] ?? 0,
      totalSpent: double.tryParse(json['total_spent'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_email': customerEmail,
      'customer_phone': customerPhone,
      'order_count': orderCount,
      'total_spent': totalSpent,
    };
  }
}

class StaffPerformance {
  final int staffId;
  final String staffName;
  final int orderCount;
  final int completedOrders;
  final double? avgProcessingHours;
  final double totalRevenue;

  StaffPerformance({
    required this.staffId,
    required this.staffName,
    required this.orderCount,
    required this.completedOrders,
    this.avgProcessingHours,
    required this.totalRevenue,
  });

  factory StaffPerformance.fromJson(Map<String, dynamic> json) {
    return StaffPerformance(
      staffId: json['staff_id'] ?? 0,
      staffName: json['staff_name'] ?? 'Unknown',
      orderCount: json['order_count'] ?? 0,
      completedOrders: json['completed_orders'] ?? 0,
      avgProcessingHours: json['avg_processing_hours'] != null
          ? double.tryParse(json['avg_processing_hours'].toString())
          : null,
      totalRevenue: double.tryParse(json['total_revenue'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'staff_id': staffId,
      'staff_name': staffName,
      'order_count': orderCount,
      'completed_orders': completedOrders,
      'avg_processing_hours': avgProcessingHours,
      'total_revenue': totalRevenue,
    };
  }

  String get formattedProcessingTime {
    if (avgProcessingHours == null) return 'N/A';
    final hours = avgProcessingHours!.floor();
    final minutes = ((avgProcessingHours! - hours) * 60).round();
    return '${hours}h ${minutes}m';
  }
}

class LaundromatComparison {
  final int laundromatId;
  final String laundromatName;
  final double revenue;
  final int orderCount;
  final int customerCount;
  final int activeOrders;
  final double? avgOrderValue;

  LaundromatComparison({
    required this.laundromatId,
    required this.laundromatName,
    required this.revenue,
    required this.orderCount,
    required this.customerCount,
    required this.activeOrders,
    this.avgOrderValue,
  });

  factory LaundromatComparison.fromJson(Map<String, dynamic> json) {
    return LaundromatComparison(
      laundromatId: json['laundromat_id'] ?? 0,
      laundromatName: json['laundromat_name'] ?? 'Unknown',
      revenue: double.tryParse(json['revenue'].toString()) ?? 0.0,
      orderCount: json['order_count'] ?? 0,
      customerCount: json['customer_count'] ?? 0,
      activeOrders: json['active_orders'] ?? 0,
      avgOrderValue: json['avg_order_value'] != null
          ? double.tryParse(json['avg_order_value'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'laundromat_id': laundromatId,
      'laundromat_name': laundromatName,
      'revenue': revenue,
      'order_count': orderCount,
      'customer_count': customerCount,
      'active_orders': activeOrders,
      'avg_order_value': avgOrderValue,
    };
  }
}

class PeakHours {
  final int hour;
  final int orderCount;
  final double revenue;

  PeakHours({
    required this.hour,
    required this.orderCount,
    required this.revenue,
  });

  factory PeakHours.fromJson(Map<String, dynamic> json) {
    return PeakHours(
      hour: json['hour'] ?? 0,
      orderCount: json['order_count'] ?? 0,
      revenue: double.tryParse(json['revenue'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hour': hour,
      'order_count': orderCount,
      'revenue': revenue,
    };
  }

  String get formattedHour {
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour $suffix';
  }
}
