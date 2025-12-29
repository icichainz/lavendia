import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../providers/receipt_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/user_model.dart';
import '../../../services/user_service.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/loading_indicator.dart';

class CreateReceiptScreen extends StatefulWidget {
  const CreateReceiptScreen({super.key});

  @override
  State<CreateReceiptScreen> createState() => _CreateReceiptScreenState();
}

class _CreateReceiptScreenState extends State<CreateReceiptScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerSearchController = TextEditingController();
  final _itemsDescriptionController = TextEditingController();
  final _itemsCountController = TextEditingController();
  final _priceController = TextEditingController();
  final _instructionsController = TextEditingController();

  final _userService = UserService();

  DateTime _expectedPickupDate = DateTime.now().add(const Duration(days: 1));
  bool _isSubmitting = false;

  // Customer search state
  UserModel? _selectedCustomer;
  List<UserModel> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _customerSearchController.dispose();
    _itemsDescriptionController.dispose();
    _itemsCountController.dispose();
    _priceController.dispose();
    _instructionsController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchCustomers(query);
    });
  }

  Future<void> _searchCustomers(String query) async {
    try {
      final results = await _userService.searchCustomers(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }

  void _selectCustomer(UserModel customer) {
    setState(() {
      _selectedCustomer = customer;
      _searchResults = [];
      _customerSearchController.clear();
    });
  }

  void _clearSelectedCustomer() {
    setState(() {
      _selectedCustomer = null;
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expectedPickupDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_expectedPickupDate),
      );

      if (time != null && mounted) {
        setState(() {
          _expectedPickupDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _submitForm() async {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('select_customer')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final receiptProvider = Provider.of<ReceiptProvider>(context, listen: false);

      final receipt = await receiptProvider.createReceipt(
        customerId: _selectedCustomer!.id,
        laundromatId: authProvider.user?.laundromatId ?? 1,
        staffId: authProvider.user?.id ?? 1,
        expectedPickupDate: _expectedPickupDate,
        itemsDescription: _itemsDescriptionController.text.trim(),
        itemsCount: int.parse(_itemsCountController.text),
        price: double.parse(_priceController.text),
        specialInstructions: _instructionsController.text.trim().isNotEmpty
            ? _instructionsController.text.trim()
            : null,
      );

      if (!mounted) return;

      if (receipt != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.translate('receipt_number')} ${receipt.receiptNumber} ${l10n.translate('receipt_created')}'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(receiptProvider.errorMessage ?? l10n.translate('receipt_create_failed')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.createReceipt),
      ),
      body: _isSubmitting
          ? const Center(child: LoadingIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer Section
                    _buildSectionHeader('Customer Information'),
                    const SizedBox(height: 12),
                    _buildCustomerSelector(),
                    const SizedBox(height: 24),

                    // Items Section
                    _buildSectionHeader('Laundry Items'),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _itemsDescriptionController,
                      label: l10n.translate('items_description'),
                      hint: l10n.translate('items_description_hint'),
                      prefixIcon: const Icon(Icons.inventory_2),
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.translate('field_required');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _itemsCountController,
                            label: l10n.translate('number_of_items'),
                            hint: '0',
                            prefixIcon: const Icon(Icons.numbers),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return l10n.translate('field_required');
                              }
                              if (int.tryParse(value) == null) {
                                return l10n.translate('field_required');
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomTextField(
                            controller: _priceController,
                            label: '${l10n.price} (\$)',
                            hint: '0.00',
                            prefixIcon: const Icon(Icons.attach_money),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return l10n.translate('field_required');
                              }
                              if (double.tryParse(value) == null) {
                                return l10n.translate('field_required');
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Pickup Date Section
                    _buildSectionHeader('Expected Pickup'),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.translate('expected_pickup_date'),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDateTime(_expectedPickupDate),
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: Theme.of(context).textTheme.bodySmall?.color),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Instructions Section
                    _buildSectionHeader('Special Instructions (Optional)'),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _instructionsController,
                      label: l10n.translate('special_instructions_optional'),
                      hint: l10n.translate('special_instructions_optional'),
                      prefixIcon: const Icon(Icons.notes),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    CustomButton(
                      text: l10n.createReceipt,
                      onPressed: _submitForm,
                      icon: Icons.receipt_long,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCustomerSelector() {
    // If a customer is selected, show the selected customer card
    if (_selectedCustomer != null) {
      return _buildSelectedCustomerCard();
    }

    // Otherwise show the search field with results
    return Column(
      children: [
        CustomTextField(
          controller: _customerSearchController,
          label: AppLocalizations.of(context)!.translate('search_customer'),
          hint: AppLocalizations.of(context)!.translate('search_by_name_phone'),
          prefixIcon: const Icon(Icons.search),
          onChanged: _onSearchChanged,
        ),
        if (_isSearching)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (_searchResults.isNotEmpty)
          _buildSearchResults()
        else if (_customerSearchController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              AppLocalizations.of(context)!.translate('no_results'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSelectedCustomerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedCustomer!.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedCustomer!.phone,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _clearSelectedCustomer,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _searchResults.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final customer = _searchResults[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              child: Text(
                customer.fullName.isNotEmpty
                    ? customer.fullName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(customer.fullName),
            subtitle: Text(customer.phone),
            trailing: Text(
              customer.email,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            onTap: () => _selectCustomer(customer),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${months[date.month - 1]} ${date.day}, ${date.year} at $hour:${date.minute.toString().padLeft(2, '0')} $period';
  }
}
