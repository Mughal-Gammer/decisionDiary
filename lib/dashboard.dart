import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'Add Decisions.dart';
import 'login page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  late Stream<DatabaseEvent> _decisionsStream;
  String _searchQuery = '';
  String _selectedFilter = 'All';
  String _selectedSort = 'Newest First';

  @override
  void initState() {
    super.initState();
    _initDecisionsStream();
  }

  void _initDecisionsStream() {
    final user = _auth.currentUser;


    _decisionsStream = _dbRef
        .child('users/${user?.uid}/decisions')
        .orderByChild('createdAt')
        .onValue;
  }

  void _navigateToAddDecision(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddDecisionScreen(),
      ),
    ).then((_) => setState(() {}));
  }

  void _showDecisionDetails(
      Map<dynamic, dynamic>
      decision, String decisionId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DecisionDetailsSheet(
        decision: decision,
        decisionId: decisionId,
        onUpdate: () => setState(() {}),
      ),
    );
  }

  Future<void> _deleteDecision(String decisionId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _dbRef.child('users/${user.uid}/decisions/$decisionId').remove();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Decision deleted successfully')),
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: ${e.toString()}')),
      );
    }
  }

  _alertDailogBox(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("LogOut"),
          content: const Text("Are you want to sure Logout?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginPage(),
                  ),
                      (route) => false,
                );
              },
              child: const Text("Yes"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("No"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Decision Diary'),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: DecisionSearchDelegate(_decisionsStream),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                if (['All', 'Completed', 'Pending'].contains(value)) {
                  _selectedFilter = value;
                } else {
                  _selectedSort = value;
                }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'Newest First',
                child: Text('Sort: Newest First'),
              ),
              const PopupMenuItem(
                value: 'Oldest First',
                child: Text('Sort: Oldest First'),
              ),
              const PopupMenuItem(
                value: 'All',
                child: Text('Filter: All'),
              ),
              const PopupMenuItem(
                value: 'Completed',
                child: Text('Filter: Completed'),
              ),
              const PopupMenuItem(
                value: 'Pending',
                child: Text('Filter: Pending'),
              ),
            ],
          ),
          IconButton(onPressed: (){
            _alertDailogBox(context);
          }
          , icon: Icon(Icons.logout_sharp))
        ],
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _decisionsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return _buildEmptyState();
          }

          final decisionsMap = snapshot.data!.snapshot.value as Map<dynamic, dynamic>? ?? {};
          final decisionIds = decisionsMap.keys.toList();
          final decisions = decisionsMap.values.toList();

          // Apply filters and sorting
          List filteredDecisions = decisions;
          List filteredIds = decisionIds;

          // Apply filter
          if (_selectedFilter == 'Completed') {
            filteredDecisions = decisions.where((d) =>
            (d['finalOutcome']?.isNotEmpty == true)).toList();
            filteredIds = decisionIds.where((id) =>
            (decisionsMap[id]?['finalOutcome']?.isNotEmpty == true)).toList();
          } else if (_selectedFilter == 'Pending') {
            filteredDecisions = decisions.where((d) =>
            (d['finalOutcome']?.isEmpty != false)).toList();
            filteredIds = decisionIds.where((id) =>
            (decisionsMap[id]?['finalOutcome']?.isEmpty != false)).toList();
          }

          // Apply search
          if (_searchQuery.isNotEmpty) {
            filteredDecisions = filteredDecisions.where((d) =>
            (d['title']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) == true ||
                d['reason']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) == true)).toList();
            filteredIds = filteredIds.where((id) =>
            (decisionsMap[id]?['title']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) == true ||
                decisionsMap[id]?['reason']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) == true)).toList();
          }

          // Apply sorting
          if (_selectedSort == 'Newest First') {
            final combined = List.generate(filteredDecisions.length,
                    (index) => {'id': filteredIds[index], 'data': filteredDecisions[index]});
            combined.sort((a, b) => (b['data']['createdAt'] ?? 0).compareTo(a['data']['createdAt'] ?? 0));
            filteredDecisions = combined.map((e) => e['data']).toList();
            filteredIds = combined.map((e) => e['id']).toList();
          } else if (_selectedSort == 'Oldest First') {
            final combined = List.generate(filteredDecisions.length,
                    (index) => {'id': filteredIds[index], 'data': filteredDecisions[index]});
            combined.sort((a, b) => (a['data']['createdAt'] ?? 0).compareTo(b['data']['createdAt'] ?? 0));
            filteredDecisions = combined.map((e) => e['data']).toList();
            filteredIds = combined.map((e) => e['id']).toList();
          }

          if (filteredDecisions.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredDecisions.length,
              itemBuilder: (context, index) {
                return DecisionCard(
                  decision: filteredDecisions[index] as Map<dynamic, dynamic>,
                  decisionId: filteredIds[index] as String,
                  onTap: () => _showDecisionDetails(
                    filteredDecisions[index] as Map<dynamic, dynamic>,
                    filteredIds[index] as String,
                  ),
                  onDelete: () => _deleteDecision(filteredIds[index] as String),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddDecision(context),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment, size: 100, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No Decisions Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by adding your first important decision',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _navigateToAddDecision(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Add First Decision'),
          ),
        ],
      ),
    );
  }
}

class DecisionCard extends StatelessWidget {
  final Map<dynamic, dynamic> decision;
  final String decisionId;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const DecisionCard({
    Key? key,
    required this.decision,
    required this.decisionId,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(decision['date'] ?? DateTime.now().toString());
    final hasFinalOutcome = decision['finalOutcome']?.isNotEmpty == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      decision['title'] ?? 'Untitled Decision',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Decision'),
                            content: const Text('Are you sure you want to delete this decision?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  onDelete();
                                },
                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (hasFinalOutcome)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade100),
                  ),
                  child: Text(
                    'Completed',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade800,
                    ),
                  ),
                ),
              Text(
                decision['reason'] ?? 'No reason provided',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd-MM-yyyy').format(date),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Spacer(),
                  if (decision['expectedOutcome']?.isNotEmpty == true)
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 16,
                          color: Colors.orange.shade400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Expected',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange.shade400,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DecisionDetailsSheet extends StatefulWidget {
  final Map<dynamic, dynamic> decision;
  final String decisionId;
  final VoidCallback onUpdate;

  const DecisionDetailsSheet({
    Key? key,
    required this.decision,
    required this.decisionId,
    required this.onUpdate,
  }) : super(key: key);

  @override
  State<DecisionDetailsSheet> createState() => _DecisionDetailsSheetState();
}

class _DecisionDetailsSheetState extends State<DecisionDetailsSheet> {
  late TextEditingController _finalOutcomeController;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _finalOutcomeController = TextEditingController(
      text: widget.decision['finalOutcome'] ?? '',
    );
  }

  @override
  void dispose() {
    _finalOutcomeController.dispose();
    super.dispose();
  }

  Future<void> _updateFinalOutcome() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      await FirebaseDatabase.instance
          .ref('users/${user.uid}/decisions/${widget.decisionId}')
          .update({
        'finalOutcome': _finalOutcomeController.text.trim(),
      });

      widget.onUpdate();
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: ${e.toString()}')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),

    ),
      child: SingleChildScrollView(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Text(
          widget.decision['title'] ?? 'No Title',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          DateFormat('dd-MM-yyyy').format(
              DateTime.fromMillisecondsSinceEpoch(widget.decision['date'] ??
                  DateTime.now().millisecondsSinceEpoch)
          ),
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 24),
        _buildDetailSection('Reason', widget.decision['reason']),
        const SizedBox(height: 20),
        _buildDetailSection('Expected Outcome', widget.decision['expectedOutcome']),
        const SizedBox(height: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Final Outcome',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                if (!_isEditing)
                  TextButton(
                    onPressed: () => setState(() => _isEditing = true),
                    child: const Text('Edit'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isEditing)
              Column(
                children: [
                  TextFormField(
                    controller: _finalOutcomeController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _isEditing = false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _updateFinalOutcome,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              )
            else
              Container(
                width: double.infinity,
                padding:  EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.decision['finalOutcome']?.isNotEmpty == true
                      ? widget.decision['finalOutcome']
                      : 'Not recorded yet',
                  style:  TextStyle(fontSize: 15),
                ),
              ),
          ],
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              padding:  EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Close'),
          ),
        ),
      ],
    ),
    ),
    );
  }

  Widget _buildDetailSection(String title, String? content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            content ?? 'Not available',
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ],
    );
  }
}

class DecisionSearchDelegate extends SearchDelegate {
  final Stream<DatabaseEvent> decisionsStream;

  DecisionSearchDelegate(this.decisionsStream);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    return StreamBuilder<DatabaseEvent>(
      stream: decisionsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Center(child: Text('No decisions found'));
        }

        final decisionsMap = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
        final filteredDecisions = decisionsMap.entries.where((entry) {
          final decision = entry.value;
          return decision['title']?.toString().toLowerCase().contains(query.toLowerCase()) == true ||
              decision['reason']?.toString().toLowerCase().contains(query.toLowerCase()) == true;
        }).toList();

        if (filteredDecisions.isEmpty) {
          return const Center(child: Text('No matching decisions'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredDecisions.length,
          itemBuilder: (context, index) {
            final entry = filteredDecisions[index];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(entry.value['title'] ?? 'Untitled Decision'),
                subtitle: Text(entry.value['reason'] ?? 'No reason provided'),
                onTap: () {
                  close(context, null);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => DecisionDetailsSheet(
                      decision: entry.value,
                      decisionId: entry.key,
                      onUpdate: () {},
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}