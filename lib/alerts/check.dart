import 'package:material_ui/material_ui.dart';

class CheckScreen extends StatelessWidget {
  const CheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My App'),
        backgroundColor: Colors.transparent, // Let body color show through
        elevation: 0,
      ),
      body: Container(
        color: Colors.purple[50], // Or your desired full-screen color
        child: Center(child: Text('Hello World!')),
      ),
    );
  }
}
