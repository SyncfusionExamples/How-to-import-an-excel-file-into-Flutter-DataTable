import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Syncfusion DataGrid Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> importedData = [];
  List<GridColumn> columns = [];

  // Handle Excel file import and load data into the DataGrid.
  Future<void> importDataGridFromExcel() async {
    clearData();

    // Picking an Excel file using FilePicker.
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result != null) {
      Uint8List? fileBytes = result.files.first.bytes;
      if (fileBytes == null) {
        String? filePath = result.files.first.path;
        if (filePath != null) {
          fileBytes = await File(filePath).readAsBytes();
        }
      }

      if (fileBytes != null) {
        var excel = Excel.decodeBytes(fileBytes);

        for (var table in excel.tables.keys) {
          var sheet = excel.tables[table];
          // Extract headers from the first row of the sheet.
          List<String> headers =
              sheet!.row(0).map((cell) => cell!.value.toString()).toList();
          // Loop through the rows starting from the second row (skipping the header).
          for (int row = 1; row < sheet.maxRows; row++) {
            Map<String, dynamic> rowData = {};
            for (int col = 0; col < headers.length; col++) {
              rowData[headers[col]] = sheet.row(row)[col]!.value;
            }
            importedData.add(rowData);
          }
        }

        if (importedData.isNotEmpty) {
          // Generate the columns.
          columns = generateColumns(importedData[0]);
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DataGridPage(
                  importedData: importedData,
                  columns: columns,
                ),
              ),
            );
          }
        }
      }
    }
  }

  // Clear previous data.
  void clearData() {
    importedData.clear();
    columns.clear();
  }

  // Dynamically generate columns based on the imported data.
  List<GridColumn> generateColumns(Map<String, dynamic> data) {
    List<GridColumn> columns = [];

    for (var entry in data.entries) {
      GridColumn gridColumn = GridColumn(
        columnName: entry.key,
        label: Container(
          padding: const EdgeInsets.all(8),
          alignment: Alignment.center,
          child: Text(entry.key),
        ),
      );

      columns.add(gridColumn);
    }

    return columns;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Excel Data'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: importDataGridFromExcel,
          child: const Text('Import from Excel'),
        ),
      ),
    );
  }
}

class DataGridPage extends StatefulWidget {
  final List<dynamic> importedData;
  final List<GridColumn> columns;

  const DataGridPage(
      {required this.importedData, required this.columns, super.key});

  @override
  DataGridPageState createState() => DataGridPageState();
}

class DataGridPageState extends State<DataGridPage> {
  late ExcelDataGridSource excelDataGridSource;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // Simulate loading data and prepare the DataGrid source.
  Future<void> loadData() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        excelDataGridSource =
            ExcelDataGridSource(widget.importedData, widget.columns);
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DataGrid'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SfDataGrid(
              source: excelDataGridSource,
              columns: widget.columns,
              columnWidthMode: ColumnWidthMode.fill,
            ),
    );
  }
}

class ExcelDataGridSource extends DataGridSource {
  ExcelDataGridSource(List<dynamic> employeeList, List<GridColumn> columns) {
    dataGridRows = employeeList.map<DataGridRow>((employee) {
      return DataGridRow(
        cells: columns.map<DataGridCell>((column) {
          var value = employee[column.columnName];
          // Handle different types of data (int, double, DateTime, String).
          if (value is IntCellValue) {
            return DataGridCell<int>(
                columnName: column.columnName, value: value.value);
          } else if (value is DoubleCellValue) {
            return DataGridCell<double>(
                columnName: column.columnName, value: value.value);
          } else if (value is DateCellValue) {
            return DataGridCell<DateTime>(
                columnName: column.columnName,
                value: DateTime(value.year, value.month, value.day));
          } else {
            return DataGridCell<String>(
                columnName: column.columnName, value: value.toString());
          }
        }).toList(),
      );
    }).toList();
  }

  List<DataGridRow> dataGridRows = [];

  @override
  List<DataGridRow> get rows => dataGridRows;

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    return DataGridRowAdapter(
        cells: row.getCells().map<Widget>((dataGridCell) {
      return Container(
          padding: const EdgeInsets.all(8),
          alignment: Alignment.center,
          child: Text(dataGridCell.value.toString()));
    }).toList());
  }
}
