import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // General
      'app_name': 'Lavendia',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'close': 'Close',
      'retry': 'Retry',
      'yes': 'Yes',
      'no': 'No',
      'ok': 'OK',
      'search': 'Search',
      'no_results': 'No results found',
      'view_all': 'View All',

      // Auth
      'login': 'Login',
      'logout': 'Logout',
      'register': 'Register',
      'email': 'Email',
      'password': 'Password',
      'confirm_password': 'Confirm Password',
      'username': 'Username',
      'phone': 'Phone',
      'forgot_password': 'Forgot Password?',
      'dont_have_account': "Don't have an account?",
      'already_have_account': 'Already have an account?',
      'sign_up': 'Sign Up',
      'sign_in': 'Sign In',
      'welcome_back': 'Welcome back,',
      'create_account': 'Create Account',
      'login_subtitle': 'Sign in to continue',
      'register_subtitle': 'Create an account to get started',
      'login_success': 'Login successful!',
      'register_success': 'Registration successful!',
      'logout_confirm': 'Are you sure you want to logout?',
      'invalid_credentials': 'Invalid credentials',
      'password_mismatch': 'Passwords do not match',
      'field_required': 'This field is required',
      'invalid_email': 'Please enter a valid email',
      'password_too_short': 'Password must be at least 6 characters',

      // Navigation
      'home': 'Home',
      'orders': 'Orders',
      'profile': 'Profile',
      'settings': 'Settings',
      'notifications': 'Notifications',

      // Customer
      'my_orders': 'My Orders',
      'active_orders': 'Active Orders',
      'completed_orders': 'Completed Orders',
      'no_orders': 'No orders yet',
      'orders_appear_here': 'Your laundry orders will appear here',
      'no_active_orders': 'No active orders',
      'no_completed_orders': 'No completed orders',
      'active_orders_appear_here': 'Your active orders will appear here',
      'completed_orders_appear_here': 'Your completed orders will appear here',
      'recent_orders': 'Recent Orders',
      'track_laundry': 'Track your laundry orders easily',
      'active': 'Active',
      'completed': 'Completed',

      // Receipt/Order Details
      'order_details': 'Order Details',
      'receipt_number': 'Receipt #',
      'status': 'Status',
      'items': 'Items',
      'items_count': '{count} items',
      'price': 'Price',
      'drop_off': 'Drop-off',
      'expected_pickup': 'Expected Pickup',
      'actual_pickup': 'Actual Pickup',
      'special_instructions': 'Special Instructions',
      'dates': 'Dates',
      'customer': 'Customer',
      'unknown_customer': 'Unknown Customer',
      'videos': 'Videos',

      // Status
      'status_pending': 'Pending',
      'status_washing': 'Washing',
      'status_drying': 'Drying',
      'status_ready': 'Ready',
      'status_completed': 'Completed',
      'status_cancelled': 'Cancelled',
      'current_status': 'Current Status',
      'update_status': 'Update Status',
      'status_updated': 'Status updated successfully!',
      'status_update_failed': 'Failed to update status',
      'mark_as': 'Mark as {status}',

      // QR Code
      'pickup_qr_code': 'Pickup QR Code',
      'show_qr_code': 'Show QR Code for Pickup',
      'scan_qr_code': 'Scan QR Code',
      'qr_instructions': 'Show this QR code to the staff when picking up your laundry',
      'waiting_for_scan': 'Waiting for staff to scan...',
      'ready_for_pickup': 'Ready for Pickup',
      'brightness_tip': 'Tip: Increase your screen brightness for easier scanning',
      'pickup_confirmed': 'Pickup Confirmed!',
      'thank_you': 'Thank you for choosing Lavendia!',
      'see_you_soon': 'We hope to see you again soon',
      'redirecting': 'Redirecting to home...',
      'point_camera': "Point camera at customer's QR code",
      'receipt_found': 'Receipt Found',
      'complete_pickup': 'Complete Pickup',
      'mark_completed_question': 'Mark this order as completed?',
      'order_completed': 'Order marked as completed!',
      'invalid_qr': 'Invalid QR code format',
      'receipt_not_found': 'Receipt not found',

      // Staff
      'manage_orders': 'Manage Orders',
      'create_receipt': 'Create Receipt',
      'scan_pickup': 'Scan Pickup',
      'all': 'All',
      'pending': 'Pending',
      'washing': 'Washing',
      'drying': 'Drying',
      'ready': 'Ready',
      'no_orders_found': 'No orders found',
      'search_customer': 'Search Customer',
      'search_by_name_phone': 'Search by name or phone...',
      'select_customer': 'Select Customer',
      'items_description': 'Items Description',
      'items_description_hint': 'e.g., 3 shirts, 2 pants',
      'number_of_items': 'Number of Items',
      'expected_pickup_date': 'Expected Pickup Date',
      'special_instructions_optional': 'Special Instructions (Optional)',
      'receipt_created': 'Receipt created successfully!',
      'receipt_create_failed': 'Failed to create receipt',

      // Profile
      'edit_profile': 'Edit Profile',
      'first_name': 'First Name',
      'last_name': 'Last Name',
      'change_password': 'Change Password',
      'current_password': 'Current Password',
      'new_password': 'New Password',
      'profile_updated': 'Profile updated successfully!',
      'password_changed': 'Password changed successfully!',
      'language': 'Language',
      'select_language': 'Select Language',
      'english': 'English',
      'french': 'French',
      'about': 'About',
      'version': 'Version',
      'terms_of_service': 'Terms of Service',
      'privacy_policy': 'Privacy Policy',
      'help_support': 'Help & Support',

      // Theme
      'theme': 'Theme',
      'select_theme': 'Select Theme',
      'theme_system': 'System',
      'theme_light': 'Light',
      'theme_dark': 'Dark',

      // Errors
      'network_error': 'Network error. Please check your connection.',
      'server_error': 'Server error. Please try again later.',
      'unknown_error': 'An unknown error occurred.',
      'session_expired': 'Session expired. Please login again.',

      // Time
      'today': 'Today',
      'yesterday': 'Yesterday',
      'days_ago': '{days} days ago',

      // Onboarding
      'onboarding_skip': 'Skip',
      'onboarding_next': 'Next',
      'onboarding_get_started': 'Get Started',
      'onboarding_page1_title': 'Welcome to Lavendia',
      'onboarding_page1_subtitle': 'Track Your Laundry',
      'onboarding_page1_description': 'Keep track of your laundry orders in real-time with easy status updates and notifications',
      'onboarding_page2_title': 'Easy QR Pickup',
      'onboarding_page2_subtitle': 'Scan & Collect',
      'onboarding_page2_description': 'Show your QR code when picking up your laundry for quick and secure collection',
      'onboarding_page3_title': 'Stay Informed',
      'onboarding_page3_subtitle': 'Real-Time Notifications',
      'onboarding_page3_description': 'Receive instant updates when your laundry status changes from washing to ready for pickup',

      // Video Upload
      'record_video': 'Record Video',
      'upload_video': 'Upload Video',
      'intake_video': 'Intake Video',
      'completion_video': 'Completion Video',
      'discard_video': 'Discard Video',
      'record_again': 'Record Again',
      'video_ready_upload': 'Video is ready to upload',
      'duration': 'Duration',
      'file_size': 'File Size',
      'uploading_video': 'Uploading Video',
      'video_uploaded_successfully': 'Video uploaded successfully!',
      'video_upload_failed': 'Failed to upload video',
      'no_videos': 'No videos available',
      'view_video': 'View Video',
      'delete_video': 'Delete Video',
      'delete_video_confirm': 'Are you sure you want to delete this video?',
      'video_deleted': 'Video deleted successfully',
      'add_video': 'Add Video',

      // Analytics
      'analytics': 'Analytics',
      'analytics_dashboard': 'Analytics Dashboard',
      'total_revenue': 'Total Revenue',
      'total_orders': 'Total Orders',
      'total_customers': 'Total Customers',
      'average_order_value': 'Avg Order Value',
      'revenue_trend': 'Revenue Trend',
      'order_status_distribution': 'Order Status',
      'top_customers': 'Top Customers',
      'staff_performance': 'Staff Performance',
      'laundromat_comparison': 'Laundromat Comparison',
      'peak_hours': 'Peak Hours',
      'export': 'Export',
      'export_pdf': 'Export PDF',
      'export_csv': 'Export CSV',
      'export_success': 'Export successful!',
      'export_failed': 'Export failed',
      'time_range_today': 'Today',
      'time_range_week': 'Week',
      'time_range_month': 'Month',
      'time_range_quarter': 'Quarter',
      'time_range_year': 'Year',
      'no_analytics_data': 'No analytics data available',
      'revenue': 'Revenue',
      'customers': 'Customers',

      // Staff Dashboard
      'staff_dashboard': 'Staff Dashboard',
      'quick_actions': 'Quick Actions',

      // Profile additional
      'personal_information': 'Personal Information',
      'email_required': 'Email is required',
      'enter_valid_email': 'Enter a valid email',
      'phone_required': 'Phone is required',
      'profile_update_failed': 'Failed to update profile',
      'choose_image_source': 'Choose Image Source',
      'camera': 'Camera',
      'gallery': 'Gallery',
      'profile_picture_updated': 'Profile picture updated successfully!',
      'change': 'Change',
      'app_version': 'Lavendia v1.0.0',

      // Create Receipt additional
      'customer_information': 'Customer Information',
      'laundry_items': 'Laundry Items',

      // Video/Camera errors
      'no_camera_found': 'No camera found on this device',
      'camera_init_failed': 'Failed to initialize camera',
      'recording_stop_failed': 'Failed to stop recording',
      'recording_start_failed': 'Failed to start recording',
      'video_pick_failed': 'Failed to pick video',
      'camera_switch_failed': 'Failed to switch camera',
      'video_load_failed': 'Failed to load video',

      // Password reset
      'enter_6_digit_code': 'Please enter a 6-digit code',
      'code_verified': 'Code verified! Enter your new password.',
      'password_reset_success': 'Password reset successfully!',

      // Notifications
      'notification_order_received': 'Order Received',
      'notification_order_pending': 'Your order #{orderNumber} has been received and is pending.',
      'notification_laundry_update': 'Laundry Update',
      'notification_order_washing': 'Your order #{orderNumber} is now being washed.',
      'notification_order_drying': 'Your order #{orderNumber} is now drying.',
      'notification_ready_pickup': 'Ready for Pickup!',
      'notification_order_ready': 'Your order #{orderNumber} is ready to collect.',
      'notification_order_complete': 'Order Complete',
      'notification_order_completed': 'Your order #{orderNumber} has been picked up. Thank you!',
      'notification_order_update': 'Order Update',
      'notification_order_status': 'Your order #{orderNumber} status: {status}',
      'notification_monitoring': 'Monitoring your laundry orders',
    },
    'fr': {
      // General
      'app_name': 'Lavendia',
      'loading': 'Chargement...',
      'error': 'Erreur',
      'success': 'Succès',
      'cancel': 'Annuler',
      'confirm': 'Confirmer',
      'save': 'Enregistrer',
      'delete': 'Supprimer',
      'edit': 'Modifier',
      'close': 'Fermer',
      'retry': 'Réessayer',
      'yes': 'Oui',
      'no': 'Non',
      'ok': 'OK',
      'search': 'Rechercher',
      'no_results': 'Aucun résultat trouvé',
      'view_all': 'Voir tout',

      // Auth
      'login': 'Connexion',
      'logout': 'Déconnexion',
      'register': "S'inscrire",
      'email': 'Email',
      'password': 'Mot de passe',
      'confirm_password': 'Confirmer le mot de passe',
      'username': "Nom d'utilisateur",
      'phone': 'Téléphone',
      'forgot_password': 'Mot de passe oublié?',
      'dont_have_account': "Vous n'avez pas de compte?",
      'already_have_account': 'Vous avez déjà un compte?',
      'sign_up': "S'inscrire",
      'sign_in': 'Se connecter',
      'welcome_back': 'Bon retour,',
      'create_account': 'Créer un compte',
      'login_subtitle': 'Connectez-vous pour continuer',
      'register_subtitle': 'Créez un compte pour commencer',
      'login_success': 'Connexion réussie!',
      'register_success': 'Inscription réussie!',
      'logout_confirm': 'Êtes-vous sûr de vouloir vous déconnecter?',
      'invalid_credentials': 'Identifiants invalides',
      'password_mismatch': 'Les mots de passe ne correspondent pas',
      'field_required': 'Ce champ est requis',
      'invalid_email': 'Veuillez entrer un email valide',
      'password_too_short': 'Le mot de passe doit contenir au moins 6 caractères',

      // Navigation
      'home': 'Accueil',
      'orders': 'Commandes',
      'profile': 'Profil',
      'settings': 'Paramètres',
      'notifications': 'Notifications',

      // Customer
      'my_orders': 'Mes commandes',
      'active_orders': 'Commandes actives',
      'completed_orders': 'Commandes terminées',
      'no_orders': 'Aucune commande',
      'orders_appear_here': 'Vos commandes de blanchisserie apparaîtront ici',
      'no_active_orders': 'Aucune commande active',
      'no_completed_orders': 'Aucune commande terminée',
      'active_orders_appear_here': 'Vos commandes actives apparaîtront ici',
      'completed_orders_appear_here': 'Vos commandes terminées apparaîtront ici',
      'recent_orders': 'Commandes récentes',
      'track_laundry': 'Suivez facilement vos commandes de blanchisserie',
      'active': 'Actives',
      'completed': 'Terminées',

      // Receipt/Order Details
      'order_details': 'Détails de la commande',
      'receipt_number': 'Reçu #',
      'status': 'Statut',
      'items': 'Articles',
      'items_count': '{count} articles',
      'price': 'Prix',
      'drop_off': 'Dépôt',
      'expected_pickup': 'Retrait prévu',
      'actual_pickup': 'Retrait effectif',
      'special_instructions': 'Instructions spéciales',
      'dates': 'Dates',
      'customer': 'Client',
      'unknown_customer': 'Client inconnu',
      'videos': 'Vidéos',

      // Status
      'status_pending': 'En attente',
      'status_washing': 'Lavage',
      'status_drying': 'Séchage',
      'status_ready': 'Prêt',
      'status_completed': 'Terminé',
      'status_cancelled': 'Annulé',
      'current_status': 'Statut actuel',
      'update_status': 'Mettre à jour le statut',
      'status_updated': 'Statut mis à jour avec succès!',
      'status_update_failed': 'Échec de la mise à jour du statut',
      'mark_as': 'Marquer comme {status}',

      // QR Code
      'pickup_qr_code': 'Code QR de retrait',
      'show_qr_code': 'Afficher le code QR pour le retrait',
      'scan_qr_code': 'Scanner le code QR',
      'qr_instructions': 'Montrez ce code QR au personnel lors du retrait de votre linge',
      'waiting_for_scan': 'En attente de scan par le personnel...',
      'ready_for_pickup': 'Prêt pour le retrait',
      'brightness_tip': 'Conseil: Augmentez la luminosité de votre écran pour faciliter le scan',
      'pickup_confirmed': 'Retrait confirmé!',
      'thank_you': 'Merci d\'avoir choisi Lavendia!',
      'see_you_soon': 'Nous espérons vous revoir bientôt',
      'redirecting': 'Redirection vers l\'accueil...',
      'point_camera': 'Pointez la caméra vers le code QR du client',
      'receipt_found': 'Reçu trouvé',
      'complete_pickup': 'Confirmer le retrait',
      'mark_completed_question': 'Marquer cette commande comme terminée?',
      'order_completed': 'Commande marquée comme terminée!',
      'invalid_qr': 'Format de code QR invalide',
      'receipt_not_found': 'Reçu non trouvé',

      // Staff
      'manage_orders': 'Gérer les commandes',
      'create_receipt': 'Créer un reçu',
      'scan_pickup': 'Scanner un retrait',
      'all': 'Tous',
      'pending': 'En attente',
      'washing': 'Lavage',
      'drying': 'Séchage',
      'ready': 'Prêt',
      'no_orders_found': 'Aucune commande trouvée',
      'search_customer': 'Rechercher un client',
      'search_by_name_phone': 'Rechercher par nom ou téléphone...',
      'select_customer': 'Sélectionner un client',
      'items_description': 'Description des articles',
      'items_description_hint': 'ex: 3 chemises, 2 pantalons',
      'number_of_items': 'Nombre d\'articles',
      'expected_pickup_date': 'Date de retrait prévue',
      'special_instructions_optional': 'Instructions spéciales (Optionnel)',
      'receipt_created': 'Reçu créé avec succès!',
      'receipt_create_failed': 'Échec de la création du reçu',

      // Profile
      'edit_profile': 'Modifier le profil',
      'first_name': 'Prénom',
      'last_name': 'Nom',
      'change_password': 'Changer le mot de passe',
      'current_password': 'Mot de passe actuel',
      'new_password': 'Nouveau mot de passe',
      'profile_updated': 'Profil mis à jour avec succès!',
      'password_changed': 'Mot de passe changé avec succès!',
      'language': 'Langue',
      'select_language': 'Sélectionner la langue',
      'english': 'Anglais',
      'french': 'Français',
      'about': 'À propos',
      'version': 'Version',
      'terms_of_service': 'Conditions d\'utilisation',
      'privacy_policy': 'Politique de confidentialité',
      'help_support': 'Aide & Support',

      // Theme
      'theme': 'Thème',
      'select_theme': 'Sélectionner le thème',
      'theme_system': 'Système',
      'theme_light': 'Clair',
      'theme_dark': 'Sombre',

      // Errors
      'network_error': 'Erreur réseau. Veuillez vérifier votre connexion.',
      'server_error': 'Erreur serveur. Veuillez réessayer plus tard.',
      'unknown_error': 'Une erreur inconnue s\'est produite.',
      'session_expired': 'Session expirée. Veuillez vous reconnecter.',

      // Time
      'today': 'Aujourd\'hui',
      'yesterday': 'Hier',
      'days_ago': 'Il y a {days} jours',

      // Onboarding
      'onboarding_skip': 'Passer',
      'onboarding_next': 'Suivant',
      'onboarding_get_started': 'Commencer',
      'onboarding_page1_title': 'Bienvenue chez Lavendia',
      'onboarding_page1_subtitle': 'Suivez Votre Linge',
      'onboarding_page1_description': 'Suivez vos commandes de blanchisserie en temps réel avec des mises à jour de statut et des notifications',
      'onboarding_page2_title': 'Retrait QR Facile',
      'onboarding_page2_subtitle': 'Scanner & Récupérer',
      'onboarding_page2_description': 'Montrez votre code QR lors du retrait de votre linge pour une collecte rapide et sécurisée',
      'onboarding_page3_title': 'Restez Informé',
      'onboarding_page3_subtitle': 'Notifications en Temps Réel',
      'onboarding_page3_description': 'Recevez des mises à jour instantanées lorsque le statut de votre linge change',

      // Video Upload
      'record_video': 'Enregistrer Vidéo',
      'upload_video': 'Télécharger Vidéo',
      'intake_video': 'Vidéo d\'Entrée',
      'completion_video': 'Vidéo de Fin',
      'discard_video': 'Supprimer Vidéo',
      'record_again': 'Enregistrer à Nouveau',
      'video_ready_upload': 'Vidéo prête à être téléchargée',
      'duration': 'Durée',
      'file_size': 'Taille du Fichier',
      'uploading_video': 'Téléchargement de la Vidéo',
      'video_uploaded_successfully': 'Vidéo téléchargée avec succès!',
      'video_upload_failed': 'Échec du téléchargement de la vidéo',
      'no_videos': 'Aucune vidéo disponible',
      'view_video': 'Voir la Vidéo',
      'delete_video': 'Supprimer la Vidéo',
      'delete_video_confirm': 'Êtes-vous sûr de vouloir supprimer cette vidéo?',
      'video_deleted': 'Vidéo supprimée avec succès',
      'add_video': 'Ajouter une Vidéo',

      // Analytics
      'analytics': 'Analyses',
      'analytics_dashboard': 'Tableau de Bord Analytique',
      'total_revenue': 'Revenu Total',
      'total_orders': 'Total Commandes',
      'total_customers': 'Total Clients',
      'average_order_value': 'Valeur Moyenne Commande',
      'revenue_trend': 'Tendance des Revenus',
      'order_status_distribution': 'Statut des Commandes',
      'top_customers': 'Meilleurs Clients',
      'staff_performance': 'Performance du Personnel',
      'laundromat_comparison': 'Comparaison Laveries',
      'peak_hours': 'Heures de Pointe',
      'export': 'Exporter',
      'export_pdf': 'Exporter PDF',
      'export_csv': 'Exporter CSV',
      'export_success': 'Export réussi!',
      'export_failed': 'Échec de l\'export',
      'time_range_today': 'Aujourd\'hui',
      'time_range_week': 'Semaine',
      'time_range_month': 'Mois',
      'time_range_quarter': 'Trimestre',
      'time_range_year': 'Année',
      'no_analytics_data': 'Aucune donnée analytique disponible',
      'revenue': 'Revenus',
      'customers': 'Clients',

      // Staff Dashboard
      'staff_dashboard': 'Tableau de Bord Personnel',
      'quick_actions': 'Actions Rapides',

      // Profile additional
      'personal_information': 'Informations Personnelles',
      'email_required': 'L\'email est requis',
      'enter_valid_email': 'Entrez un email valide',
      'phone_required': 'Le téléphone est requis',
      'profile_update_failed': 'Échec de la mise à jour du profil',
      'choose_image_source': 'Choisir la Source de l\'Image',
      'camera': 'Caméra',
      'gallery': 'Galerie',
      'profile_picture_updated': 'Photo de profil mise à jour avec succès!',
      'change': 'Changer',
      'app_version': 'Lavendia v1.0.0',

      // Create Receipt additional
      'customer_information': 'Informations Client',
      'laundry_items': 'Articles de Blanchisserie',

      // Video/Camera errors
      'no_camera_found': 'Aucune caméra trouvée sur cet appareil',
      'camera_init_failed': 'Échec de l\'initialisation de la caméra',
      'recording_stop_failed': 'Échec de l\'arrêt de l\'enregistrement',
      'recording_start_failed': 'Échec du démarrage de l\'enregistrement',
      'video_pick_failed': 'Échec de la sélection de la vidéo',
      'camera_switch_failed': 'Échec du changement de caméra',
      'video_load_failed': 'Échec du chargement de la vidéo',

      // Password reset
      'enter_6_digit_code': 'Veuillez entrer un code à 6 chiffres',
      'code_verified': 'Code vérifié! Entrez votre nouveau mot de passe.',
      'password_reset_success': 'Mot de passe réinitialisé avec succès!',

      // Notifications
      'notification_order_received': 'Commande Reçue',
      'notification_order_pending': 'Votre commande #{orderNumber} a été reçue et est en attente.',
      'notification_laundry_update': 'Mise à Jour Blanchisserie',
      'notification_order_washing': 'Votre commande #{orderNumber} est en cours de lavage.',
      'notification_order_drying': 'Votre commande #{orderNumber} est en cours de séchage.',
      'notification_ready_pickup': 'Prêt pour le Retrait!',
      'notification_order_ready': 'Votre commande #{orderNumber} est prête à être récupérée.',
      'notification_order_complete': 'Commande Terminée',
      'notification_order_completed': 'Votre commande #{orderNumber} a été récupérée. Merci!',
      'notification_order_update': 'Mise à Jour Commande',
      'notification_order_status': 'Votre commande #{orderNumber} statut: {status}',
      'notification_monitoring': 'Surveillance de vos commandes de blanchisserie',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }

  String translateWithArgs(String key, Map<String, String> args) {
    String translation = translate(key);
    args.forEach((argKey, argValue) {
      translation = translation.replaceAll('{$argKey}', argValue);
    });
    return translation;
  }

  // Convenience getters for common translations
  String get appName => translate('app_name');
  String get loading => translate('loading');
  String get error => translate('error');
  String get success => translate('success');
  String get cancel => translate('cancel');
  String get confirm => translate('confirm');
  String get save => translate('save');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get close => translate('close');
  String get retry => translate('retry');
  String get yes => translate('yes');
  String get no => translate('no');
  String get ok => translate('ok');
  String get search => translate('search');
  String get viewAll => translate('view_all');

  // Auth
  String get login => translate('login');
  String get logout => translate('logout');
  String get register => translate('register');
  String get email => translate('email');
  String get password => translate('password');
  String get confirmPassword => translate('confirm_password');
  String get username => translate('username');
  String get phone => translate('phone');
  String get forgotPassword => translate('forgot_password');
  String get dontHaveAccount => translate('dont_have_account');
  String get alreadyHaveAccount => translate('already_have_account');
  String get signUp => translate('sign_up');
  String get signIn => translate('sign_in');
  String get welcomeBack => translate('welcome_back');
  String get createAccount => translate('create_account');

  // Navigation
  String get home => translate('home');
  String get orders => translate('orders');
  String get profile => translate('profile');
  String get settings => translate('settings');

  // Customer
  String get myOrders => translate('my_orders');
  String get activeOrders => translate('active_orders');
  String get completedOrders => translate('completed_orders');
  String get noOrders => translate('no_orders');
  String get recentOrders => translate('recent_orders');
  String get trackLaundry => translate('track_laundry');
  String get active => translate('active');
  String get completed => translate('completed');

  // Order Details
  String get orderDetails => translate('order_details');
  String get status => translate('status');
  String get items => translate('items');
  String get price => translate('price');
  String get dropOff => translate('drop_off');
  String get expectedPickup => translate('expected_pickup');
  String get specialInstructions => translate('special_instructions');
  String get dates => translate('dates');
  String get customer => translate('customer');
  String get unknownCustomer => translate('unknown_customer');
  String get videos => translate('videos');

  // Status translations
  String getStatusTranslation(String status) {
    switch (status) {
      case 'pending':
        return translate('status_pending');
      case 'washing':
        return translate('status_washing');
      case 'drying':
        return translate('status_drying');
      case 'ready':
        return translate('status_ready');
      case 'completed':
        return translate('status_completed');
      case 'cancelled':
        return translate('status_cancelled');
      default:
        return status;
    }
  }

  // QR Code
  String get pickupQrCode => translate('pickup_qr_code');
  String get showQrCode => translate('show_qr_code');
  String get scanQrCode => translate('scan_qr_code');
  String get qrInstructions => translate('qr_instructions');
  String get waitingForScan => translate('waiting_for_scan');
  String get readyForPickup => translate('ready_for_pickup');
  String get brightnessTip => translate('brightness_tip');
  String get pickupConfirmed => translate('pickup_confirmed');
  String get thankYou => translate('thank_you');
  String get seeYouSoon => translate('see_you_soon');

  // Staff
  String get manageOrders => translate('manage_orders');
  String get createReceipt => translate('create_receipt');
  String get scanPickup => translate('scan_pickup');
  String get all => translate('all');

  // Profile
  String get editProfile => translate('edit_profile');
  String get firstName => translate('first_name');
  String get lastName => translate('last_name');
  String get changePassword => translate('change_password');
  String get language => translate('language');
  String get selectLanguage => translate('select_language');
  String get english => translate('english');
  String get french => translate('french');
  String get about => translate('about');
  String get version => translate('version');

  // Items count with argument
  String itemsCount(int count) {
    return translateWithArgs('items_count', {'count': count.toString()});
  }

  // Onboarding
  String get onboardingSkip => translate('onboarding_skip');
  String get onboardingNext => translate('onboarding_next');
  String get onboardingGetStarted => translate('onboarding_get_started');
  String get onboardingPage1Title => translate('onboarding_page1_title');
  String get onboardingPage1Subtitle => translate('onboarding_page1_subtitle');
  String get onboardingPage1Description => translate('onboarding_page1_description');
  String get onboardingPage2Title => translate('onboarding_page2_title');
  String get onboardingPage2Subtitle => translate('onboarding_page2_subtitle');
  String get onboardingPage2Description => translate('onboarding_page2_description');
  String get onboardingPage3Title => translate('onboarding_page3_title');
  String get onboardingPage3Subtitle => translate('onboarding_page3_subtitle');
  String get onboardingPage3Description => translate('onboarding_page3_description');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'fr'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
