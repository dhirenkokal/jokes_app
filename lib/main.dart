import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class Joke {
  final String type;
  final String setup;
  final String punchline;
  final int id;

  Joke({
    required this.type,
    required this.setup,
    required this.punchline,
    required this.id,
  });

  factory Joke.fromJson(Map<String, dynamic> json) {
    return Joke(
      type: json['type'],
      setup: json['setup'],
      punchline: json['punchline'],
      id: json['id'],
    );
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  void _toggleDarkMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jokes Application',
      theme: _isDarkMode
          ? ThemeData.dark().copyWith(
        // Adjust dark mode colors here
        scaffoldBackgroundColor: Colors.black87,
        cardColor: Colors.grey[800],
        textTheme: ThemeData.dark().textTheme.apply(bodyColor: Colors.white),
      )
          : ThemeData.light().copyWith(
        // Adjust light mode colors here
        scaffoldBackgroundColor: Colors.white,
        cardColor: Colors.grey[200],
      ),
      home: JokePage(toggleDarkMode: _toggleDarkMode),
    );
  }
}

class JokePage extends StatefulWidget {
  final VoidCallback toggleDarkMode;

  const JokePage({Key? key, required this.toggleDarkMode}) : super(key: key);

  @override
  _JokePageState createState() => _JokePageState();
}

class _JokePageState extends State<JokePage> {
  late Future<List<Joke>> futureJokes;

  @override
  void initState() {
    super.initState();
    futureJokes = fetchJokes();
  }

  Future<List<Joke>> fetchJokes() async {
    try {
      final response = await http
          .get(Uri.parse('https://official-joke-api.appspot.com/random_ten'));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((e) => Joke.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load jokes');
      }
    } catch (e) {
      throw Exception('Please turn on internet to load jokes');
    }
  }

  void _showJokeDialog(Joke joke) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(joke.setup),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(joke.punchline),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: '${joke.setup}\n${joke.punchline}'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Copied to clipboard'),
                        ),
                      );
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Copy',
                      style: TextStyle(color: Colors.blueAccent),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Close',
                      style: TextStyle(color: Colors.blueAccent),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _refreshJokes() async {
    setState(() {
      futureJokes = fetchJokes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshJokes,
        child: Center(
          child: FutureBuilder<List<Joke>>(
            future: futureJokes,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                final jokes = snapshot.data!;
                return ListView.builder(
                  itemCount: jokes.length,
                  itemBuilder: (context, index) {
                    final joke = jokes[index];
                    return GestureDetector(
                      onTap: () => _showJokeDialog(joke),
                      child: Card(
                        color: Theme.of(context).cardColor,
                        child: ListTile(
                          title: Text(
                            joke.setup,
                            style: Theme.of(context).textTheme.bodyText1,
                          ),
                          subtitle: Text(
                            joke.punchline,
                            style: Theme.of(context).textTheme.bodyText2,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
            },
          ),
        ),
      ),
      appBar: AppBar(
        title: Text('Joke Application'),
        actions: [
          IconButton(
            icon: Icon(Icons.light_mode),
            onPressed: widget.toggleDarkMode,
          ),
        ],
      ),
    );
  }
}
m