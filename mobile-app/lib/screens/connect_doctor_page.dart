import 'package:flutter/material.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/screens/chat_page.dart';

class Doctor {
  final String id;
  final String name;
  final String location;
  final String contacts;
  final String services;
  final String availabilitySlots;
  final String otherInfo;
  String connectionStatus; // 'none', 'pending', 'accepted'

  Doctor({
    required this.id,
    required this.name,
    required this.location,
    required this.contacts,
    required this.services,
    required this.availabilitySlots,
    required this.otherInfo,
    this.connectionStatus = 'none',
  });
}

class ConnectClinicPage extends StatefulWidget {
  const ConnectClinicPage({super.key});

  @override
  State<ConnectClinicPage> createState() => _ConnectClinicPageState();
}

class _ConnectClinicPageState extends State<ConnectClinicPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  final List<Doctor> _doctors = [
    Doctor(
      id: '1',
      name: 'Dr. Sarah Johnson',
      location: 'Central Maternity Hospital',
      contacts: 'sarah.j@example.com, +123456789',
      services: 'Obstetrics, Prenatal Care',
      availabilitySlots: 'Mon-Wed: 9 AM - 2 PM',
      otherInfo: 'Specializes in high-risk pregnancies and provides personalized birth planning.',
      connectionStatus: 'none',
    ),
    Doctor(
      id: '2',
      name: 'Dr. Emily Wang',
      location: 'Women\'s Health Clinic',
      contacts: 'emily.w@example.com, +987654321',
      services: 'Gynecology, Postpartum Care',
      availabilitySlots: 'Tue-Thu: 10 AM - 4 PM',
      otherInfo: 'Focuses on natural birthing techniques and postpartum mental health.',
      connectionStatus: 'accepted',
    ),
    Doctor(
      id: '3',
      name: 'Dr. Michael Brown',
      location: 'City General',
      contacts: 'mbrown@example.com, +112233445',
      services: 'Fetal Medicine',
      availabilitySlots: 'Fri: 8 AM - 5 PM',
      otherInfo: 'Expert in fetal ultrasound and diagnosing congenital conditions early.',
      connectionStatus: 'none',
    ),
    Doctor(
      id: '4',
      name: 'Midwife Anna Smith',
      location: 'Lotus Birthing Center',
      contacts: 'anna.midwife@example.com, +445566778',
      services: 'Midwifery, Lactation Consulting',
      availabilitySlots: 'Mon-Fri: On Call',
      otherInfo: 'Provides comprehensive ongoing support throughout pregnancy and natural birth.',
      connectionStatus: 'pending',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDoctorDetails(Doctor doctor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.medical_services, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doctor.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text(doctor.services, style: const TextStyle(color: Colors.black54)),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailRow(Icons.location_on, 'Location', doctor.location),
              _buildDetailRow(Icons.phone, 'Contacts', doctor.contacts),
              _buildDetailRow(Icons.access_time, 'Availability', doctor.availabilitySlots),
              const SizedBox(height: 16),
              const Text('Important Information for Pregnancy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text(doctor.otherInfo, style: const TextStyle(color: Colors.black87, height: 1.4)),
              const SizedBox(height: 24),
              if (doctor.connectionStatus == 'none')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        doctor.connectionStatus = 'pending';
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Connection request sent!')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Connect', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 15)),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableDoctors = _doctors.where((d) => 
      (d.connectionStatus == 'none' || d.connectionStatus == 'pending') && 
      (d.name.toLowerCase().contains(_searchQuery) || d.services.toLowerCase().contains(_searchQuery))
    ).toList();
    
    final acceptedDoctors = _doctors.where((d) => d.connectionStatus == 'accepted').toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Connect Doctor', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.black),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.black54,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Available Doctors'),
              Tab(text: 'My Doctors'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Available Doctors
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by name or service',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: availableDoctors.length,
                    itemBuilder: (context, index) {
                      final doc = availableDoctors[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                        child: InkWell(
                          onTap: () => _showDoctorDetails(doc),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  radius: 25,
                                  backgroundColor: AppColors.primary,
                                  child: Icon(Icons.person, color: Colors.white),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(doc.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(height: 4),
                                      Text(doc.services, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Expanded(child: Text(doc.location, style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis)),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (doc.connectionStatus == 'pending')
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.orange[100],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text('Pending', style: TextStyle(color: Colors.deepOrange, fontSize: 12)),
                                  )
                                else
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        doc.connectionStatus = 'pending';
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Connection request sent!')),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                      minimumSize: const Size(0, 32),
                                    ),
                                    child: const Text('Connect', style: TextStyle(color: Colors.white, fontSize: 12)),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            
            // Tab 2: My Doctors (Accepted)
            acceptedDoctors.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('No accepted doctors yet', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: acceptedDoctors.length,
                    itemBuilder: (context, index) {
                      final doc = acceptedDoctors[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                        child: InkWell(
                          onTap: () => _showDoctorDetails(doc),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  radius: 25,
                                  backgroundColor: Colors.green,
                                  child: Icon(Icons.check, color: Colors.white),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(doc.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(height: 4),
                                      Text(doc.services, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                                    ],
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatPage(doctorName: doc.name),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.white),
                                  label: const Text('Chat', style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                    minimumSize: const Size(0, 32),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
