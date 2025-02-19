# How to import an excel file into Flutter DataTable (SfDataGrid)?

In this article, we will show you how to import an excel file into [Flutter DataTable](https://www.syncfusion.com/flutter-widgets/flutter-datagrid).

## Steps to Import an Excel File into Flutter DataTable

### Step 1: Extracting Data from Excel

The file picker should allow the selection of .xlsx files. Once an Excel file is selected, decode it using the `Excel.decodeBytes` method from the excel package. Extract the headers from the first row and the data starting from the second row. Dynamically generate columns by iterating over the headers and creating a [GridColumn](https://pub.dev/documentation/syncfusion_flutter_datagrid/latest/datagrid/GridColumn-class.html) for each one.

```dart
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
```

### Step 2: Displaying Data in SfDataGrid

Display a CircularProgressIndicator while the data is loading. Once the data is loaded, pass the prepared DataGridSource to the [SfDataGrid]() widget to render the grid.

```dart
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
```

You can download this example on [GitHub](https://github.com/SyncfusionExamples/How-to-import-an-excel-file-into-Flutter-DataTable).