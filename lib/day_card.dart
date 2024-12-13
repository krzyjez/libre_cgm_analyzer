import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DayCardBuilder {
  static Widget buildDayCard(dynamic day) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nagłówek
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12.0),
              topRight: Radius.circular(12.0),
            ),
            child: Container(
              width: double.infinity,
              color: Colors.grey[800],
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Data: ${DateFormat('yyyy-MM-dd').format(day.date)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          // Obszar roboczy
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Buba"),
          ),
        ],
      ),
    );
  }
}
