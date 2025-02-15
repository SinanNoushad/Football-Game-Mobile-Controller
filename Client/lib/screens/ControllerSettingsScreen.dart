import 'package:flutter/material.dart';
import '../controller_settings.dart';  // Make sure this helper file is in the correct path

class ControllerSettingsScreen extends StatefulWidget {
  @override
  _ControllerSettingsScreenState createState() => _ControllerSettingsScreenState();
}

class _ControllerSettingsScreenState extends State<ControllerSettingsScreen> {
  final TextEditingController nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load the saved controller name (if any)
    ControllerSettings.getControllerName().then((value) {
      if (value != null) {
        setState(() {
          nameController.text = value;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Controller Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Controller Name",
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Save the new controller name.
                ControllerSettings.setControllerName(nameController.text);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Controller name saved.")),
                );
              },
              child: Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
