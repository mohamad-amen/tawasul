import 'package:flutter/material.dart';

class DividerWidget extends StatelessWidget {
  const DividerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SizedBox(
          width: 20,
        ),
        Expanded(
            child: Divider(
          thickness: 2,
        )),
        Padding(
          padding: EdgeInsets.fromLTRB(5, 0, 5, 0),
          child: Text(
            "Or",
            style: TextStyle(color: Colors.grey, fontSize: 17),
          ),
        ),
        Expanded(
            child: Divider(
          thickness: 2,
        )),
        SizedBox(
          width: 20,
        )
      ],
    );
  }
}
