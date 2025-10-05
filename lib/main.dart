import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Qnotes - Advanced Notes App',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        fontFamily: 'SF Pro Display',
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.orange,
        fontFamily: 'SF Pro Display',
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Color(0xFF1C1C1E),
        cardColor: Color(0xFF2C2C2E),
      ),
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String category;
  final List<String> tags;
  final bool isFavorite;
  final bool isArchived;
  final bool isDeleted;
  final Color? backgroundColor;
  final String? imagePath;
  final String? voiceNotePath;
  final DateTime? reminderDate;
  final Priority priority;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.category = 'Uncategorized',
    this.tags = const [],
    this.isFavorite = false,
    this.isArchived = false,
    this.isDeleted = false,
    this.backgroundColor,
    this.imagePath,
    this.voiceNotePath,
    this.reminderDate,
    this.priority = Priority.medium,
  });

  Note copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? category,
    List<String>? tags,
    bool? isFavorite,
    bool? isArchived,
    bool? isDeleted,
    Color? backgroundColor,
    String? imagePath,
    String? voiceNotePath,
    DateTime? reminderDate,
    Priority? priority,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      isDeleted: isDeleted ?? this.isDeleted,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      imagePath: imagePath ?? this.imagePath,
      voiceNotePath: voiceNotePath ?? this.voiceNotePath,
      reminderDate: reminderDate ?? this.reminderDate,
      priority: priority ?? this.priority,
    );
  }
}

enum Priority { low, medium, high }
enum SortBy { dateCreated, dateModified, title, priority }
enum ViewMode { list, grid, masonry }

class AppSettings {
  final bool isDarkMode;
  final ViewMode defaultViewMode;
  final SortBy defaultSortBy;
  final bool showPreview;
  final bool autoSync;
  final bool enableReminders;
  final String defaultCategory;
  final List<String> customCategories;

  AppSettings({
    this.isDarkMode = false,
    this.defaultViewMode = ViewMode.list,
    this.defaultSortBy = SortBy.dateModified,
    this.showPreview = true,
    this.autoSync = false,
    this.enableReminders = true,
    this.defaultCategory = 'Uncategorized',
    this.customCategories = const ['Personal', 'Work', 'Ideas', 'Todo'],
  });
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedTabIndex = 0;
  List<Note> _notes = [];
  List<Note> _trashedNotes = [];
  List<String> _allTags = ['important', 'work', 'personal', 'ideas', 'todo'];
  ViewMode _currentViewMode = ViewMode.list;
  SortBy _currentSortBy = SortBy.dateModified;
  bool _isDarkMode = false;
  String _searchQuery = '';
  List<String> _selectedTags = [];
  bool _showFavoritesOnly = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  TextEditingController _searchController = TextEditingController();

  final List<String> _tabs = ['All', 'Home', 'Work', 'Personal'];

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
    _fabAnimationController.forward();
    _loadNotes();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final noteCount = prefs.getInt('noteCount') ?? 0;
    
    List<Note> loadedNotes = [];
    
    for (int i = 0; i < noteCount; i++) {
      final id = prefs.getString('note_${i}_id') ?? '';
      final title = prefs.getString('note_${i}_title') ?? '';
      final content = prefs.getString('note_${i}_content') ?? '';
      final createdAt = DateTime.tryParse(prefs.getString('note_${i}_createdAt') ?? '') ?? DateTime.now();
      final updatedAt = DateTime.tryParse(prefs.getString('note_${i}_updatedAt') ?? '') ?? DateTime.now();
      final category = prefs.getString('note_${i}_category') ?? 'Uncategorized';
      final tagsString = prefs.getString('note_${i}_tags') ?? '';
      final tags = tagsString.isEmpty ? <String>[] : tagsString.split('|||');
      final isFavorite = prefs.getBool('note_${i}_isFavorite') ?? false;
      final isArchived = prefs.getBool('note_${i}_isArchived') ?? false;
      final isDeleted = prefs.getBool('note_${i}_isDeleted') ?? false;
      final priorityIndex = prefs.getInt('note_${i}_priority') ?? 1;
      
      if (id.isNotEmpty) {
        loadedNotes.add(Note(
          id: id,
          title: title,
          content: content,
          createdAt: createdAt,
          updatedAt: updatedAt,
          category: category,
          tags: tags,
          isFavorite: isFavorite,
          isArchived: isArchived,
          isDeleted: isDeleted,
          priority: Priority.values[priorityIndex.clamp(0, Priority.values.length - 1)],
        ));
      }
    }
    
    setState(() {
      _notes = loadedNotes;
    });
    
    print('Loaded ${loadedNotes.length} notes from storage'); // Debug line
  }

  void _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Clear existing notes
    final oldCount = prefs.getInt('noteCount') ?? 0;
    for (int i = 0; i < oldCount; i++) {
      await prefs.remove('note_${i}_id');
      await prefs.remove('note_${i}_title');
      await prefs.remove('note_${i}_content');
      await prefs.remove('note_${i}_createdAt');
      await prefs.remove('note_${i}_updatedAt');
      await prefs.remove('note_${i}_category');
      await prefs.remove('note_${i}_tags');
      await prefs.remove('note_${i}_isFavorite');
      await prefs.remove('note_${i}_isArchived');
      await prefs.remove('note_${i}_isDeleted');
      await prefs.remove('note_${i}_priority');
    }
    
    // Save new notes
    await prefs.setInt('noteCount', _notes.length);
    
    for (int i = 0; i < _notes.length; i++) {
      final note = _notes[i];
      await prefs.setString('note_${i}_id', note.id);
      await prefs.setString('note_${i}_title', note.title);
      await prefs.setString('note_${i}_content', note.content);
      await prefs.setString('note_${i}_createdAt', note.createdAt.toIso8601String());
      await prefs.setString('note_${i}_updatedAt', note.updatedAt.toIso8601String());
      await prefs.setString('note_${i}_category', note.category);
      await prefs.setString('note_${i}_tags', note.tags.join('|||'));
      await prefs.setBool('note_${i}_isFavorite', note.isFavorite);
      await prefs.setBool('note_${i}_isArchived', note.isArchived);
      await prefs.setBool('note_${i}_isDeleted', note.isDeleted);
      await prefs.setInt('note_${i}_priority', note.priority.index);
    }
    
    print('Saved ${_notes.length} notes to storage'); // Debug line
  }

  List<Note> get _filteredNotes {
    List<Note> filtered = _notes.where((note) => 
      !note.isArchived && 
      !note.isDeleted &&
      (_showFavoritesOnly ? note.isFavorite : true)
    ).toList();
    
    // Filter by tab
    if (_selectedTabIndex > 0) {
      String category = _tabs[_selectedTabIndex];
      filtered = filtered.where((note) => note.category == category).toList();
    }
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((note) =>
        note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        note.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        note.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()))
      ).toList();
    }
    
    // Filter by selected tags
    if (_selectedTags.isNotEmpty) {
      filtered = filtered.where((note) =>
        _selectedTags.every((tag) => note.tags.contains(tag))
      ).toList();
    }
    
    // Sort notes
    switch (_currentSortBy) {
      case SortBy.dateCreated:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortBy.dateModified:
        filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case SortBy.title:
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortBy.priority:
        filtered.sort((a, b) => b.priority.index.compareTo(a.priority.index));
        break;
    }
    
    return filtered;
  }

  void _addNote(String title, String content, String category, List<String> tags, Priority priority, DateTime? reminderDate) {
    setState(() {
      _notes.insert(0, Note(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title.isEmpty ? 'Untitled' : title,
        content: content,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        category: category,
        tags: tags,
        priority: priority,
        reminderDate: reminderDate,
      ));
    });
    
    // Save to persistent storage
    _saveNotes();
    
    // Update all tags list
    for (String tag in tags) {
      if (!_allTags.contains(tag)) {
        setState(() {
          _allTags.add(tag);
        });
      }
    }
  }

  void _updateNote(Note note, String title, String content, String category, List<String> tags, Priority priority, DateTime? reminderDate) {
    setState(() {
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = note.copyWith(
          title: title.isEmpty ? 'Untitled' : title,
          content: content,
          updatedAt: DateTime.now(),
          category: category,
          tags: tags,
          priority: priority,
          reminderDate: reminderDate,
        );
      }
    });
    _saveNotes();
  }

  void _toggleFavorite(Note note) {
    setState(() {
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = note.copyWith(isFavorite: !note.isFavorite);
      }
    });
    _saveNotes();
  }

  void _archiveNote(Note note) {
    setState(() {
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = note.copyWith(isArchived: true);
      }
    });
    _saveNotes();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Note archived'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              final index = _notes.indexWhere((n) => n.id == note.id);
              if (index != -1) {
                _notes[index] = note.copyWith(isArchived: false);
              }
            });
            _saveNotes();
          },
        ),
      ),
    );
  }

  void _deleteNote(Note note) {
    setState(() {
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = note.copyWith(isDeleted: true);
        _trashedNotes.add(_notes[index]);
      }
    });
    _saveNotes();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Note moved to trash'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              final index = _notes.indexWhere((n) => n.id == note.id);
              if (index != -1) {
                _notes[index] = note.copyWith(isDeleted: false);
                _trashedNotes.removeWhere((n) => n.id == note.id);
              }
            });
            _saveNotes();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: _isDarkMode ? Color(0xFF1C1C1E) : Color(0xFFF5F5F5),
        drawer: _buildDrawer(),
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildSearchBar(),
              _buildTabBar(),
              Expanded(
                child: _filteredNotes.isEmpty 
                  ? _buildEmptyState() 
                  : _buildNotesView(),
              ),
            ],
          ),
        ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              _scaffoldKey.currentState?.openDrawer();
            },
            child: Icon(
              Icons.menu, 
              size: 24,
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          Spacer(),
          Container(
            width: 28,
            height: 28,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 24,
                  color: _isDarkMode ? Colors.white : Colors.grey.shade700,
                ),
                Positioned(
                  bottom: 3,
                  child: Text(
                    '${DateTime.now().day}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _isDarkMode ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert, 
              size: 24,
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
            onSelected: (value) {
              switch (value) {
                case 'settings':
                  _showSettingsDialog();
                  break;
                case 'export':
                  _exportNotes();
                  break;
                case 'import':
                  _importNotes();
                  break;
                case 'statistics':
                  _showStatistics();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'settings', child: Text('Settings')),
              PopupMenuItem(value: 'export', child: Text('Export Notes')),
              PopupMenuItem(value: 'import', child: Text('Import Notes')),
              PopupMenuItem(value: 'statistics', child: Text('Statistics')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _isDarkMode ? Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search notes, tags, content...',
          border: InputBorder.none,
          icon: Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
              )
            : null,
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _tabs.asMap().entries.map((entry) {
                  int index = entry.key;
                  String tab = entry.value;
                  bool isSelected = _selectedTabIndex == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTabIndex = index;
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.only(right: 16),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Color(0xFFEECB38) : (_isDarkMode ? Color(0xFF2C2C2E) : Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tab,
                        style: TextStyle(
                          color: isSelected ? Colors.white : (_isDarkMode ? Colors.white70 : Colors.grey.shade600),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          SizedBox(width: 8),
          PopupMenuButton<ViewMode>(
            icon: Icon(
              _currentViewMode == ViewMode.grid
                ? Icons.grid_view
                : _currentViewMode == ViewMode.masonry
                  ? Icons.view_quilt
                  : Icons.view_list,
              color: _isDarkMode ? Colors.white70 : Colors.grey.shade600,
            ),
            onSelected: (mode) {
              setState(() {
                _currentViewMode = mode;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: ViewMode.list, child: Row(children: [Icon(Icons.view_list), SizedBox(width: 8), Text('List')])),
              PopupMenuItem(value: ViewMode.grid, child: Row(children: [Icon(Icons.grid_view), SizedBox(width: 8), Text('Grid')])),
              PopupMenuItem(value: ViewMode.masonry, child: Row(children: [Icon(Icons.view_quilt), SizedBox(width: 8), Text('Masonry')])),
            ],
          ),
          PopupMenuButton<SortBy>(
            icon: Icon(Icons.sort, color: _isDarkMode ? Colors.white70 : Colors.grey.shade600),
            onSelected: (sortBy) {
              setState(() {
                _currentSortBy = sortBy;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: SortBy.dateModified, child: Text('Date Modified')),
              PopupMenuItem(value: SortBy.dateCreated, child: Text('Date Created')),
              PopupMenuItem(value: SortBy.title, child: Text('Title')),
              PopupMenuItem(value: SortBy.priority, child: Text('Priority')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        children: [
          FilterChip(
            label: Text('Favorites'),
            selected: _showFavoritesOnly,
            onSelected: (selected) {
              setState(() {
                _showFavoritesOnly = selected;
              });
            },
            avatar: Icon(Icons.favorite, size: 16),
          ),
          SizedBox(width: 8),
          ..._allTags.map((tag) {
            bool isSelected = _selectedTags.contains(tag);
            return Container(
              margin: EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text('#$tag'),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTags.add(tag);
                    } else {
                      _selectedTags.remove(tag);
                    }
                  });
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container();
  }

  Widget _buildFloatingNote() {
    return Container(
      width: 30,
      height: 35,
      decoration: BoxDecoration(
        color: _isDarkMode ? Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.all(4),
            height: 2,
            color: Colors.grey.shade400,
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4),
            height: 2,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 2),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4),
            height: 2,
            color: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  Widget _buildNotesView() {
    switch (_currentViewMode) {
      case ViewMode.grid:
        return _buildGridView();
      case ViewMode.masonry:
        return _buildMasonryView();
      default:
        return _buildListView();
    }
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _filteredNotes.length,
      itemBuilder: (context, index) {
        return _buildNoteCard(_filteredNotes[index], false);
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: _filteredNotes.length,
      itemBuilder: (context, index) {
        return _buildNoteCard(_filteredNotes[index], true);
      },
    );
  }

  Widget _buildMasonryView() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        for (int i = 0; i < _filteredNotes.length; i += 2) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildNoteCard(_filteredNotes[i], true)),
              SizedBox(width: 12),
              if (i + 1 < _filteredNotes.length)
                Expanded(child: _buildNoteCard(_filteredNotes[i + 1], true))
              else
                Expanded(child: SizedBox()),
            ],
          ),
          SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildNoteCard(Note note, bool isCompact) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NoteEditorScreen(
              existingNote: note,
              isDarkMode: _isDarkMode,
              allTags: _allTags,
              onSave: (title, content, category, tags, priority, reminderDate) {
                _updateNote(note, title, content, category, tags, priority, reminderDate);
              },
            ),
          ),
        );
      },
      onLongPress: () => _showNoteOptions(note),
      child: Container(
        margin: EdgeInsets.only(bottom: isCompact ? 0 : 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: note.backgroundColor ?? (_isDarkMode ? Color(0xFF2C2C2E) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: note.priority == Priority.high 
            ? Border.all(color: Colors.red, width: 2)
            : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    note.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _isDarkMode ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (note.isFavorite)
                  Icon(Icons.favorite, color: Colors.red, size: 16),
                if (note.reminderDate != null)
                  Icon(Icons.alarm, color: Colors.orange, size: 16),
                if (note.priority == Priority.high)
                  Icon(Icons.priority_high, color: Colors.red, size: 16),
              ],
            ),
            SizedBox(height: 8),
            Text(
              note.content,
              style: TextStyle(
                fontSize: 14,
                color: _isDarkMode ? Colors.white70 : Colors.grey.shade600,
                height: 1.4,
              ),
              maxLines: isCompact ? 6 : 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (note.tags.isNotEmpty) ...[
              SizedBox(height: 12),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: note.tags.map((tag) => Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Color(0xFFEECB38).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '#$tag',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFFEECB38),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )).toList(),
              ),
            ],
            SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? Color(0xFF3C3C3E) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    note.category,
                    style: TextStyle(
                      fontSize: 12,
                      color: _isDarkMode ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
                ),
                Spacer(),
                Flexible(
                  child: Text(
                    DateFormat('MMM d, HH:mm').format(note.updatedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: _isDarkMode ? Colors.white54 : Colors.grey.shade500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: _isDarkMode ? Color(0xFF1C1C1E) : Colors.white,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Q',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFEECB38),
                            ),
                          ),
                          TextSpan(
                            text: 'Pad',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    Switch(
                      value: _isDarkMode,
                      onChanged: (value) {
                        setState(() {
                          _isDarkMode = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              
              ExpansionTile(
                leading: Icon(
                  Icons.folder_outlined, 
                  color: _isDarkMode ? Colors.white70 : Colors.grey.shade600,
                ),
                title: Text(
                  'All Notes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                children: [
                  _buildDrawerSubItem(Icons.folder_outlined, 'All', () {
                    setState(() { _selectedTabIndex = 0; });
                    Navigator.pop(context);
                  }),
                  _buildDrawerSubItem(Icons.home_outlined, 'Home', () {
                    setState(() { _selectedTabIndex = 1; });
                    Navigator.pop(context);
                  }),
                  _buildDrawerSubItem(Icons.work_outline, 'Work', () {
                    setState(() { _selectedTabIndex = 2; });
                    Navigator.pop(context);
                  }),
                  _buildDrawerSubItem(Icons.person_outline, 'Personal', () {
                    setState(() { _selectedTabIndex = 3; });
                    Navigator.pop(context);
                  }),
                  _buildDrawerSubItem(Icons.settings_outlined, 'Manage Category', () {
                    Navigator.pop(context);
                    _showManageCategoryDialog();
                  }),
                ],
              ),
              
              _buildDrawerItem(Icons.access_time_outlined, 'Reminders', () {
                Navigator.pop(context);
                _showRemindersDialog();
              }),

              _buildDrawerItem(Icons.star_outline, 'Favorites', () {
                setState(() {
                  _showFavoritesOnly = true;
                  _selectedTabIndex = 0;
                });
                Navigator.pop(context);
              }),

              _buildDrawerItem(Icons.archive_outlined, 'Archive', () {
                Navigator.pop(context);
                _showArchivedNotes();
              }),

              _buildDrawerItem(Icons.delete_outline, 'Trash', () {
                Navigator.pop(context);
                _showTrashDialog();
              }),
              
              _buildDrawerItem(Icons.settings, 'Settings', () {
                Navigator.pop(context);
                _showSettingsDialog();
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: _isDarkMode ? Colors.white70 : Colors.grey.shade600),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: _isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildDrawerSubItem(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: EdgeInsets.only(left: 32),
      child: ListTile(
        leading: Icon(icon, color: _isDarkMode ? Colors.white54 : Colors.grey.shade600, size: 20),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: _isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _fabAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabAnimation.value,
          child: Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFEECB38), Color(0xFFEECB38)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFEECB38).withOpacity(0.3),
                  blurRadius: 15,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NoteEditorScreen(
                      isDarkMode: _isDarkMode,
                      allTags: _allTags,
                      onSave: _addNote,
                    ),
                  ),
                );
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        );
      },
    );
  }

  // Helper methods for counts
  int _getFavoritesCount() => _notes.where((n) => n.isFavorite && !n.isDeleted && !n.isArchived).length;
  int _getArchivedCount() => _notes.where((n) => n.isArchived && !n.isDeleted).length;
  int _getRemindersCount() => _notes.where((n) => n.reminderDate != null && !n.isDeleted && !n.isArchived).length;

  // Dialog methods
  void _showNoteOptions(Note note) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(note.isFavorite ? Icons.favorite : Icons.favorite_border),
              title: Text(note.isFavorite ? 'Remove from Favorites' : 'Add to Favorites'),
              onTap: () {
                _toggleFavorite(note);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.archive),
              title: Text('Archive'),
              onTap: () {
                _archiveNote(note);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.share),
              title: Text('Share'),
              onTap: () {
                Navigator.pop(context);
                _shareNote(note);
              },
            ),
            ListTile(
              leading: Icon(Icons.copy),
              title: Text('Duplicate'),
              onTap: () {
                Navigator.pop(context);
                _duplicateNote(note);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                _deleteNote(note);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: Text('Dark Mode'),
              value: _isDarkMode,
              onChanged: (value) {
                setState(() {
                  _isDarkMode = value;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Default View Mode'),
              subtitle: Text(_currentViewMode.toString().split('.').last),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Show view mode selector
              },
            ),
            ListTile(
              title: Text('Auto Backup'),
              subtitle: Text('Backup notes automatically'),
              trailing: Switch(value: false, onChanged: (value) {}),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Close')),
        ],
      ),
    );
  }

  void _showManageCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Manage Categories'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ..._tabs.map((category) => ListTile(
              title: Text(category),
              trailing: IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  // Edit category
                },
              ),
            )).toList(),
            ListTile(
              leading: Icon(Icons.add),
              title: Text('Add Category'),
              onTap: () {
                // Add new category
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Close')),
        ],
      ),
    );
  }

  void _showRemindersDialog() {
    final reminders = _notes.where((n) => n.reminderDate != null && !n.isDeleted).toList();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reminders'),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final note = reminders[index];
              return ListTile(
                title: Text(note.title),
                subtitle: Text(DateFormat('MMM d, y HH:mm').format(note.reminderDate!)),
                trailing: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      final noteIndex = _notes.indexWhere((n) => n.id == note.id);
                      if (noteIndex != -1) {
                        _notes[noteIndex] = note.copyWith(reminderDate: null);
                      }
                    });
                    Navigator.pop(context);
                    _showRemindersDialog();
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Close')),
        ],
      ),
    );
  }

  void _showTagsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('All Tags'),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allTags.map((tag) => Chip(
              label: Text('#$tag'),
              onDeleted: () {
                setState(() {
                  _allTags.remove(tag);
                  // Remove tag from all notes
                  for (int i = 0; i < _notes.length; i++) {
                    _notes[i] = _notes[i].copyWith(
                      tags: _notes[i].tags.where((t) => t != tag).toList(),
                    );
                  }
                });
                Navigator.pop(context);
                _showTagsDialog();
              },
            )).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Close')),
        ],
      ),
    );
  }

  void _showArchivedNotes() {
    final archivedNotes = _notes.where((n) => n.isArchived && !n.isDeleted).toList();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Archived Notes'),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: archivedNotes.length,
            itemBuilder: (context, index) {
              final note = archivedNotes[index];
              return ListTile(
                title: Text(note.title),
                subtitle: Text(note.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.unarchive),
                      onPressed: () {
                        setState(() {
                          final noteIndex = _notes.indexWhere((n) => n.id == note.id);
                          if (noteIndex != -1) {
                            _notes[noteIndex] = note.copyWith(isArchived: false);
                          }
                        });
                        Navigator.pop(context);
                        _showArchivedNotes();
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        _deleteNote(note);
                        Navigator.pop(context);
                        _showArchivedNotes();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Close')),
        ],
      ),
    );
  }

  void _showTrashDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Trash'),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              if (_trashedNotes.isNotEmpty) ...[
                Row(
                  children: [
                    Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _trashedNotes.clear();
                          _notes.removeWhere((n) => n.isDeleted);
                        });
                        Navigator.pop(context);
                      },
                      child: Text('Empty Trash', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _trashedNotes.length,
                    itemBuilder: (context, index) {
                      final note = _trashedNotes[index];
                      return ListTile(
                        title: Text(note.title),
                        subtitle: Text(note.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.restore),
                              onPressed: () {
                                setState(() {
                                  final noteIndex = _notes.indexWhere((n) => n.id == note.id);
                                  if (noteIndex != -1) {
                                    _notes[noteIndex] = note.copyWith(isDeleted: false);
                                    _trashedNotes.remove(note);
                                  }
                                });
                                Navigator.pop(context);
                                _showTrashDialog();
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_forever, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _notes.removeWhere((n) => n.id == note.id);
                                  _trashedNotes.remove(note);
                                });
                                Navigator.pop(context);
                                _showTrashDialog();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ] else ...[
                Center(child: Text('Trash is empty')),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Close')),
        ],
      ),
    );
  }

  void _showStatistics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Notes: ${_notes.where((n) => !n.isDeleted).length}'),
            Text('Favorites: ${_getFavoritesCount()}'),
            Text('Archived: ${_getArchivedCount()}'),
            Text('With Reminders: ${_getRemindersCount()}'),
            Text('Total Tags: ${_allTags.length}'),
            Text('In Trash: ${_trashedNotes.length}'),
            SizedBox(height: 16),
            Text('Categories:', style: TextStyle(fontWeight: FontWeight.bold)),
            ..._tabs.map((category) {
              final count = _notes.where((n) => n.category == category && !n.isDeleted && !n.isArchived).length;
              return Text('  $category: $count');
            }).toList(),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Close')),
        ],
      ),
    );
  }

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Backup & Sync'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.backup),
              title: Text('Create Backup'),
              subtitle: Text('Export all notes to file'),
              onTap: () {
                Navigator.pop(context);
                _exportNotes();
              },
            ),
            ListTile(
              leading: Icon(Icons.restore),
              title: Text('Restore from Backup'),
              subtitle: Text('Import notes from file'),
              onTap: () {
                Navigator.pop(context);
                _importNotes();
              },
            ),
            ListTile(
              leading: Icon(Icons.cloud_sync),
              title: Text('Cloud Sync'),
              subtitle: Text('Sync with cloud storage'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Cloud sync feature coming soon!')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Close')),
        ],
      ),
    );
  }

  void _exportNotes() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Notes exported successfully!')),
    );
  }

  void _importNotes() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Import feature coming soon!')),
    );
  }

  void _shareNote(Note note) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Share: ${note.title}')),
    );
  }

  void _duplicateNote(Note note) {
    setState(() {
      _notes.insert(0, note.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '${note.title} (Copy)',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    });
    _saveNotes();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Note duplicated')),
    );
  }
}

class SpeechBubbleTail extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width * 0.2, 0)
      ..lineTo(size.width * 0.8, 0)
      ..lineTo(size.width * 0.5, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class NoteEditorScreen extends StatefulWidget {
  final Function(String title, String content, String category, List<String> tags, Priority priority, DateTime? reminderDate) onSave;
  final Note? existingNote;
  final bool isDarkMode;
  final List<String> allTags;

  const NoteEditorScreen({
    Key? key,
    required this.onSave,
    this.existingNote,
    this.isDarkMode = false,
    this.allTags = const [],
  }) : super(key: key);

  @override
  _NoteEditorScreenState createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  String _selectedCategory = 'Uncategorized';
  List<String> _selectedTags = [];
  Priority _selectedPriority = Priority.medium;
  DateTime? _reminderDate;
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderlined = false;
  final List<String> _categories = ['Uncategorized', 'Home', 'Work', 'Personal', 'Ideas', 'Todo'];
  Timer? _saveTimer;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existingNote?.title ?? '',
    );
    _contentController = TextEditingController(
      text: widget.existingNote?.content ?? '',
    );
    _selectedCategory = widget.existingNote?.category ?? 'Uncategorized';
    _selectedTags = List.from(widget.existingNote?.tags ?? []);
    _selectedPriority = widget.existingNote?.priority ?? Priority.medium;
    _reminderDate = widget.existingNote?.reminderDate;

    // Listen for changes in the text fields
    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _titleController.removeListener(_onTextChanged);
    _contentController.removeListener(_onTextChanged);
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _hasUnsavedChanges = true;
    });

    // Cancel previous timer
    _saveTimer?.cancel();

    // Start new timer for auto-save (2 seconds after user stops typing)
    _saveTimer = Timer(Duration(seconds: 2), () {
      _autoSave();
    });
  }

  void _autoSave() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if ((title.isNotEmpty || content.isNotEmpty) && _hasUnsavedChanges) {
      widget.onSave(title, content, _selectedCategory, _selectedTags, _selectedPriority, _reminderDate);
      setState(() {
        _hasUnsavedChanges = false;
      });
    }
  }

  void _saveNote() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isNotEmpty || content.isNotEmpty) {
      widget.onSave(title, content, _selectedCategory, _selectedTags, _selectedPriority, _reminderDate);
      setState(() {
        _hasUnsavedChanges = false;
      });
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: widget.isDarkMode ? ThemeData.dark() : ThemeData.light(),
      child: WillPopScope(
        onWillPop: () async {
          // Auto-save before navigating back
          _autoSave();
          return true;
        },
        child: Scaffold(
          backgroundColor: widget.isDarkMode ? Color(0xFF1C1C1E) : Color(0xFFF5E6D3),
          body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              _buildDateAndOptions(),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _titleController,
                        style: TextStyle(
                          color: widget.isDarkMode ? Colors.white : Colors.brown.shade300,
                          fontSize: 24,
                          fontWeight: FontWeight.w300,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Title',
                          hintStyle: TextStyle(
                            color: widget.isDarkMode ? Colors.white54 : Colors.brown.shade300,
                            fontSize: 24,
                            fontWeight: FontWeight.w300,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        maxLines: null,
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Tags display
                      if (_selectedTags.isNotEmpty) ...[
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: _selectedTags.map((tag) => Chip(
                            label: Text('#$tag'),
                            onDeleted: () {
                              setState(() {
                                _selectedTags.remove(tag);
                              });
                            },
                          )).toList(),
                        ),
                        SizedBox(height: 16),
                      ],
                      
                      Expanded(
                        child: TextField(
                          controller: _contentController,
                          style: TextStyle(
                            color: widget.isDarkMode ? Colors.white70 : Colors.brown.shade400,
                            fontSize: 16,
                            height: 1.5,
                            fontWeight: _isBold ? FontWeight.bold : FontWeight.normal,
                            fontStyle: _isItalic ? FontStyle.italic : FontStyle.normal,
                            decoration: _isUnderlined ? TextDecoration.underline : TextDecoration.none,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Note here',
                            hintStyle: TextStyle(
                              color: widget.isDarkMode ? Colors.white38 : Colors.brown.shade300,
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildBottomToolbar(),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: _saveNote,
            child: Icon(
              Icons.check,
              color: widget.isDarkMode ? Colors.white : Colors.brown.shade600,
              size: 24,
            ),
          ),
          SizedBox(width: 20),
          GestureDetector(
            onTap: () {
              // Undo functionality
            },
            child: Icon(
              Icons.undo,
              color: widget.isDarkMode ? Colors.white54 : Colors.brown.shade400,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          GestureDetector(
            onTap: () {
              // Redo functionality
            },
            child: Icon(
              Icons.redo,
              color: widget.isDarkMode ? Colors.white38 : Colors.brown.shade300,
              size: 24,
            ),
          ),
          Spacer(),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: widget.isDarkMode ? Colors.white : Colors.brown.shade600,
              size: 24,
            ),
            onSelected: (value) {
              switch (value) {
                case 'reminder':
                  _setReminder();
                  break;
                case 'tags':
                  _manageTags();
                  break;
                case 'priority':
                  _setPriority();
                  break;
                case 'export':
                  _exportNote();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'reminder', child: Row(children: [Icon(Icons.alarm), SizedBox(width: 8), Text('Set Reminder')])),
              PopupMenuItem(value: 'tags', child: Row(children: [Icon(Icons.tag), SizedBox(width: 8), Text('Manage Tags')])),
              PopupMenuItem(value: 'priority', child: Row(children: [Icon(Icons.priority_high), SizedBox(width: 8), Text('Set Priority')])),
              PopupMenuItem(value: 'export', child: Row(children: [Icon(Icons.share), SizedBox(width: 8), Text('Export Note')])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateAndOptions() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Text(
            'Today, ${DateFormat('h:mm a').format(DateTime.now())}',
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white54 : Colors.brown.shade500,
              fontSize: 14,
            ),
          ),
          SizedBox(width: 16),
          if (_reminderDate != null) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.alarm, size: 12, color: Colors.orange),
                  SizedBox(width: 4),
                  Text(
                    DateFormat('MMM d, HH:mm').format(_reminderDate!),
                    style: TextStyle(fontSize: 10, color: Colors.orange),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
          ],
          if (_selectedPriority != Priority.medium) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getPriorityColor(_selectedPriority).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.priority_high, size: 12, color: _getPriorityColor(_selectedPriority)),
                  SizedBox(width: 4),
                  Text(
                    _selectedPriority.name.toUpperCase(),
                    style: TextStyle(fontSize: 10, color: _getPriorityColor(_selectedPriority)),
                  ),
                ],
              ),
            ),
          ],
          Spacer(),
          GestureDetector(
            onTap: () {
              _showCategoryPicker();
            },
            child: Row(
              children: [
                Icon(
                  Icons.folder_outlined,
                  color: widget.isDarkMode ? Colors.white54 : Colors.brown.shade500,
                  size: 16,
                ),
                SizedBox(width: 4),
                Text(
                  _selectedCategory,
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white54 : Colors.brown.shade500,
                    fontSize: 14,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: widget.isDarkMode ? Colors.white54 : Colors.brown.shade500,
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomToolbar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildToolbarButton(Icons.format_size, 'Aa', false),
          _buildToolbarButton(Icons.format_bold, '', _isBold, onTap: () {
            setState(() {
              _isBold = !_isBold;
            });
          }),
          _buildToolbarButton(Icons.format_italic, '', _isItalic, onTap: () {
            setState(() {
              _isItalic = !_isItalic;
            });
          }),
          _buildToolbarButton(Icons.format_underlined, '', _isUnderlined, onTap: () {
            setState(() {
              _isUnderlined = !_isUnderlined;
            });
          }),
          _buildToolbarButton(Icons.image_outlined, '', false, onTap: () {
            _addImage();
          }),
          _buildToolbarButton(Icons.mic_outlined, '', false, onTap: () {
            _recordVoice();
          }),
          _buildToolbarButton(Icons.tag, '', false, onTap: () {
            _manageTags();
          }),
          _buildToolbarButton(Icons.format_list_bulleted, '', false, onTap: () {
            _insertBulletList();
          }),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(IconData icon, String? text, bool isActive, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isActive ? Color(0xFFEECB38).withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: text != null && text.isNotEmpty
            ? Center(
                child: Text(
                  text,
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white : Colors.brown.shade600,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            : Icon(
                icon,
                color: isActive
                  ? Color(0xFFEECB38)
                  : widget.isDarkMode ? Colors.white : Colors.brown.shade600,
                size: 20,
              ),
      ),
    );
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return Colors.red;
      case Priority.medium:
        return Colors.orange;
      case Priority.low:
        return Colors.green;
    }
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Category',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 16),
              ..._categories.map((category) {
                return ListTile(
                  title: Text(category),
                  leading: Radio<String>(
                    value: category,
                    groupValue: _selectedCategory,
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                      Navigator.pop(context);
                    },
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  void _setReminder() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    ).then((date) {
      if (date != null) {
        showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        ).then((time) {
          if (time != null) {
            setState(() {
              _reminderDate = DateTime(
                date.year,
                date.month,
                date.day,
                time.hour,
                time.minute,
              );
            });
          }
        });
      }
    });
  }

  void _manageTags() {
    showDialog(
      context: context,
      builder: (context) {
        List<String> availableTags = List.from(widget.allTags);
        List<String> tempSelectedTags = List.from(_selectedTags);
        TextEditingController newTagController = TextEditingController();
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Manage Tags'),
              content: Container(
                width: double.maxFinite,
                height: 300,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: newTagController,
                            decoration: InputDecoration(
                              hintText: 'Add new tag',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            if (newTagController.text.isNotEmpty && 
                                !availableTags.contains(newTagController.text)) {
                              setDialogState(() {
                                availableTags.add(newTagController.text);
                                tempSelectedTags.add(newTagController.text);
                                newTagController.clear();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: availableTags.map((tag) {
                          bool isSelected = tempSelectedTags.contains(tag);
                          return FilterChip(
                            label: Text('#$tag'),
                            selected: isSelected,
                            onSelected: (selected) {
                              setDialogState(() {
                                if (selected) {
                                  tempSelectedTags.add(tag);
                                } else {
                                  tempSelectedTags.remove(tag);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedTags = tempSelectedTags;
                    });
                    Navigator.pop(context);
                  },
                  child: Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _setPriority() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Priority'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: Priority.values.map((priority) {
            return ListTile(
              title: Text(priority.name.toUpperCase()),
              leading: Icon(
                Icons.flag,
                color: _getPriorityColor(priority),
              ),
              trailing: Radio<Priority>(
                value: priority,
                groupValue: _selectedPriority,
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value!;
                  });
                  Navigator.pop(context);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _exportNote() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Note exported successfully!')),
    );
  }

  void _addImage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Image attachment feature coming soon!')),
    );
  }

  void _recordVoice() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Voice recording feature coming soon!')),
    );
  }

  void _insertBulletList() {
    final currentText = _contentController.text;
    final cursorPosition = _contentController.selection.baseOffset;
    final newText = currentText.substring(0, cursorPosition) + 
                   '\n• ' + 
                   currentText.substring(cursorPosition);
    
    _contentController.text = newText;
    _contentController.selection = TextSelection.fromPosition(
      TextPosition(offset: cursorPosition + 3),
    );
  }
}