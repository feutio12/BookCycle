import 'package:flutter/material.dart';

class AdminDataTable extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;

  const AdminDataTable({
    required this.columns,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          columns: columns,
          rows: rows,
          headingRowColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) => Colors.grey[200]!,
          ),
          dataRowHeight: 60,
          headingRowHeight: 50,
          horizontalMargin: 16,
          columnSpacing: 16,
          showCheckboxColumn: false,
        ),
      ),
    );
  }
}