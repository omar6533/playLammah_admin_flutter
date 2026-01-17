import 'package:flutter/material.dart';

class CustomDataTable extends StatefulWidget {
  final List<String> columns;
  final List<List<String>> rows;
  final Function(int)? onEdit;
  final Function(int)? onDelete;
  final int pageSize;

  const CustomDataTable({
    required this.columns,
    required this.rows,
    this.onEdit,
    this.onDelete,
    this.pageSize = 30,
    super.key,
  });

  @override
  State<CustomDataTable> createState() => _CustomDataTableState();
}

class _CustomDataTableState extends State<CustomDataTable> {
  int _currentPage = 0;

  int get _totalPages => (widget.rows.length / widget.pageSize).ceil();
  int get _startIndex => _currentPage * widget.pageSize;
  int get _endIndex =>
      (_startIndex + widget.pageSize).clamp(0, widget.rows.length);
  List<List<String>> get _currentPageRows =>
      widget.rows.sublist(_startIndex, _endIndex);

  void _goToPage(int page) {
    setState(() {
      _currentPage = page.clamp(0, _totalPages - 1);
    });
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _goToPage(_currentPage + 1);
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _goToPage(_currentPage - 1);
    }
  }

  @override
  void didUpdateWidget(CustomDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset to first page if data changed significantly
    if (oldWidget.rows.length != widget.rows.length) {
      _currentPage = 0;
    }
    // Adjust current page if it's out of bounds
    if (_currentPage >= _totalPages && _totalPages > 0) {
      _currentPage = _totalPages - 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, outerConstraints) {
        return Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: constraints.maxWidth > 0
                                ? constraints.maxWidth
                                : 800,
                          ),
                          child: DataTable(
                            columns: [
                              ...widget.columns.map((col) => DataColumn(
                                    label: Text(
                                      col,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  )),
                              if (widget.onEdit != null ||
                                  widget.onDelete != null)
                                const DataColumn(
                                  label: Text('Actions',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ),
                            ],
                            rows: _currentPageRows.asMap().entries.map((entry) {
                              final localIndex = entry.key;
                              final row = entry.value;
                              final globalIndex = _startIndex + localIndex;
                              return DataRow(
                                cells: [
                                  ...row.map((cell) => DataCell(
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(
                                              maxWidth: 200),
                                          child: Text(
                                            cell,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                          ),
                                        ),
                                      )),
                                  if (widget.onEdit != null ||
                                      widget.onDelete != null)
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (widget.onEdit != null)
                                            IconButton(
                                              icon: const Icon(Icons.edit,
                                                  size: 20, color: Colors.blue),
                                              onPressed: () =>
                                                  widget.onEdit!(globalIndex),
                                            ),
                                          if (widget.onDelete != null)
                                            IconButton(
                                              icon: const Icon(Icons.delete,
                                                  size: 20, color: Colors.red),
                                              onPressed: () =>
                                                  widget.onDelete!(globalIndex),
                                            ),
                                        ],
                                      ),
                                    ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Showing ${_startIndex + 1}-$_endIndex of ${widget.rows.length}',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                    ),
                  ),
                  if (_totalPages > 1)
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: _currentPage > 0 ? _previousPage : null,
                          tooltip: 'Previous page',
                        ),
                        const SizedBox(width: 8),
                        ...List.generate(
                          _totalPages > 7 ? 7 : _totalPages,
                          (index) {
                            int pageIndex;
                            if (_totalPages <= 7) {
                              pageIndex = index;
                            } else if (_currentPage < 3) {
                              pageIndex = index;
                            } else if (_currentPage > _totalPages - 4) {
                              pageIndex = _totalPages - 7 + index;
                            } else {
                              pageIndex = _currentPage - 3 + index;
                            }

                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: InkWell(
                                onTap: () => _goToPage(pageIndex),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: _currentPage == pageIndex
                                        ? Colors.blue
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${pageIndex + 1}',
                                      style: TextStyle(
                                        color: _currentPage == pageIndex
                                            ? Colors.white
                                            : const Color(0xFF111827),
                                        fontWeight: _currentPage == pageIndex
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        if (_totalPages > 7 && _currentPage < _totalPages - 4)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Text('...',
                                style: TextStyle(color: Color(0xFF6B7280))),
                          ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed:
                              _currentPage < _totalPages - 1 ? _nextPage : null,
                          tooltip: 'Next page',
                        ),
                      ],
                    )
                  else
                    const SizedBox.shrink(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
