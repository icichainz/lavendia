from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from apps.laundromats.models import Laundromat
from apps.receipts.models import Receipt
from datetime import datetime, timedelta

User = get_user_model()


class Command(BaseCommand):
    help = 'Creates test data for development'

    def handle(self, *args, **kwargs):
        self.stdout.write('Creating test data...')

        # Create admin user
        if not User.objects.filter(username='admin').exists():
            admin = User.objects.create_superuser(
                username='admin',
                email='admin@lavendia.com',
                phone='+1234567890',
                password='admin123',
                role='admin'
            )
            self.stdout.write(self.style.SUCCESS('Created admin user: admin / admin123'))

        # Create laundromats
        laundromat1 = Laundromat.objects.create(
            name='Downtown Laundry',
            address='123 Main St, Downtown',
            phone='+1234567891',
            email='downtown@lavendia.com'
        )

        laundromat2 = Laundromat.objects.create(
            name='Uptown Wash & Dry',
            address='456 Park Ave, Uptown',
            phone='+1234567892',
            email='uptown@lavendia.com'
        )

        self.stdout.write(self.style.SUCCESS('Created 2 laundromats'))

        # Create staff users
        staff1 = User.objects.create_user(
            username='staff1',
            email='staff1@lavendia.com',
            phone='+1234567893',
            password='staff123',
            role='staff',
            laundromat=laundromat1,
            first_name='John',
            last_name='Smith'
        )

        staff2 = User.objects.create_user(
            username='staff2',
            email='staff2@lavendia.com',
            phone='+1234567894',
            password='staff123',
            role='staff',
            laundromat=laundromat2,
            first_name='Jane',
            last_name='Doe'
        )

        self.stdout.write(self.style.SUCCESS('Created 2 staff users'))

        # Create customer users
        customer1 = User.objects.create_user(
            username='customer1',
            email='customer1@example.com',
            phone='+1234567895',
            password='customer123',
            role='customer',
            first_name='Alice',
            last_name='Johnson'
        )

        customer2 = User.objects.create_user(
            username='customer2',
            email='customer2@example.com',
            phone='+1234567896',
            password='customer123',
            role='customer',
            first_name='Bob',
            last_name='Williams'
        )

        self.stdout.write(self.style.SUCCESS('Created 2 customer users'))

        # Create sample receipts
        Receipt.objects.create(
            laundromat=laundromat1,
            customer=customer1,
            staff=staff1,
            expected_pickup_date=datetime.now() + timedelta(days=2),
            items_description='3 shirts, 2 pants, 1 jacket',
            items_count=6,
            special_instructions='Please use gentle detergent',
            price=25.50,
            status='pending'
        )

        Receipt.objects.create(
            laundromat=laundromat1,
            customer=customer2,
            staff=staff1,
            expected_pickup_date=datetime.now() + timedelta(days=1),
            items_description='2 dresses, 1 coat',
            items_count=3,
            price=18.00,
            status='washing'
        )

        Receipt.objects.create(
            laundromat=laundromat2,
            customer=customer1,
            staff=staff2,
            expected_pickup_date=datetime.now() + timedelta(hours=12),
            items_description='5 t-shirts, 3 jeans',
            items_count=8,
            price=30.00,
            status='ready'
        )

        self.stdout.write(self.style.SUCCESS('Created 3 sample receipts'))

        self.stdout.write(self.style.SUCCESS('\n=== Test Data Created Successfully ===\n'))
        self.stdout.write('Admin User:')
        self.stdout.write('  Username: admin')
        self.stdout.write('  Password: admin123\n')
        self.stdout.write('Staff Users:')
        self.stdout.write('  Username: staff1, staff2')
        self.stdout.write('  Password: staff123\n')
        self.stdout.write('Customer Users:')
        self.stdout.write('  Username: customer1, customer2')
        self.stdout.write('  Password: customer123\n')
