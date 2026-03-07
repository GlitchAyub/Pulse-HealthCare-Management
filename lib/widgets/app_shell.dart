import 'package:flutter/material.dart';
import 'package:pulse/pages/more_page.dart';
import '../core/auth_scope.dart';
import '../pages/appointments_page.dart';
import '../pages/home_page.dart';
import '../pages/specialists_page.dart';
import 'doctor/doctor_shell.dart';
import 'admin/admin_shell.dart';
import 'patient/patient_shell.dart';
import 'partner/partner_shell.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    SpecialistsPage(),
    AppointmentsPage(),
    MorePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = AuthScope.of(context).user;
    if (user?.role == 'admin') {
      return const AdminShell();
    }
    final role = user?.role ?? '';
    if (role == 'patient' || role.contains('patient')) {
      return const PatientShell();
    }
    if (role == 'partner' || role.contains('partner')) {
      return const PartnerShell();
    }
    if (role == 'medical_professional' || role.contains('medical')) {
      return const DoctorShell();
    }
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.local_hospital_rounded), label: 'Doctors'),
          NavigationDestination(
              icon: Icon(Icons.calendar_month_rounded), label: 'Schedule'),
          NavigationDestination(icon: Icon(Icons.menu_rounded), label: 'More'),
        ],
      ),
    );
  }
}
