import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:deligood/core/network/api.dart';

class ConfirmOrderPage extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String locality;

  const ConfirmOrderPage({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.locality,
  });

  @override
  State<ConfirmOrderPage> createState() => _ConfirmOrderPageState();
}

class _ConfirmOrderPageState extends State<ConfirmOrderPage> {
  bool isLoading = false;

  Future<void> confirmOrder() async {
    setState(() => isLoading = true);
    try {
      await LivreurApi.confirmOrder(
        firstName: widget.firstName,
        lastName: widget.lastName,
        phoneNumber: widget.phoneNumber,
        locality: widget.locality,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Commande confirmée !"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur confirmation : $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirmation de commande"),
        backgroundColor: Colors.deepOrange,
      ),
      body: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 3.h),
            Text(
              "Vérifiez vos informations :",
              style: TextStyle(fontSize: 15.sp),
            ),
            SizedBox(height: 2.h),
            _infoRow("Prénom", widget.firstName),
            _infoRow("Nom", widget.lastName),
            _infoRow("Téléphone", widget.phoneNumber),
            _infoRow("Localité", widget.locality),
            SizedBox(height: 5.h),
            ElevatedButton(
              onPressed: isLoading ? null : confirmOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                padding: EdgeInsets.symmetric(vertical: 2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3.h),
                ),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      "Confirmer la commande",
                      style: TextStyle(fontSize: 16.sp, color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
          ),
          Text(value, style: TextStyle(fontSize: 14.sp)),
        ],
      ),
    );
  }
}
