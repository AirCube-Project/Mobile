import 'package:flutter/material.dart';

class BeautyButton extends StatelessWidget {
  String text;

  Color background;

  Color foreground;

  Function onClick;

  double elevation;

  BeautyButton(
      {this.text,
      this.background,
      this.onClick,
      this.foreground,
      this.elevation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(right: 8),
      child: OutlinedButton(
          onPressed: () {
            onClick();
          },
          style: OutlinedButton.styleFrom(
              elevation: elevation,
              backgroundColor: background,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24))),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              text,
              style: TextStyle(fontSize: 16, color: foreground),
            ),
          )),
    );
  }
}
