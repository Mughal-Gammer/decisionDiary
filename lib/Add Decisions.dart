import 'package:flutter/material.dart';

class AddDecisions extends StatefulWidget {
  const AddDecisions({super.key});

  @override
  State<AddDecisions> createState() => _AddDecisionsState();
}

class _AddDecisionsState extends State<AddDecisions> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
        Center(child: Text('Add Decisions',style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black
          ,
        ),)),
      ),
      body:Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal:16.0),
            child: TextFormField(
              decoration: InputDecoration(
                hintText: 'Decision',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 24.0, horizontal: 12.0),
              ),
            ),
          )
        ],
      )
    );
  }
}
