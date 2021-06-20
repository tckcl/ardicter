import 'dart:convert';

import 'package:arabdict/word.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SearchPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return SearchPageState();
  }
}

class SearchPageState extends State<SearchPage> {
  var suggestions = [];

  void showWord(String word) {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => new WordPage(word)));
  }

  void getSuggestions(String q) {
    if (q.isEmpty) return;
    setState(() {
      if (suggestions.isEmpty) {
        suggestions.add("");
      }
      suggestions.removeAt(0);
      suggestions.insert(0, q);
    });
    String url = "https://www.arabdict.com//suggest.php?dict=de&query=" + q;
    // TODO: add the current word.
    try {
      http.Client().get(Uri.parse(url)).then((value) {
        setState(() {
          suggestions.removeRange(1, suggestions.length);
          suggestions.insertAll(1, jsonDecode(value.body));
        });
      });
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: TextField(
            autofocus: true,
            decoration: InputDecoration(
                border: OutlineInputBorder(), hintText: "search term."),
            onChanged: (value) => getSuggestions(value),
          ),
        ),
        body: ListView.builder(
            itemCount: suggestions.length,
            itemBuilder: (BuildContext context, int index) {
              String word = suggestions[index];
              return Container(
                child: GestureDetector(
                  onTap: () {
                    // Show page.
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => new WordPage(word)));
                  },
                  child: Container(
                    // TODO: add some animation on selecting.
                    padding: EdgeInsets.all(10),
                    child: Text(word),
                  ),
                ),
              );
            }),
      ),
    );
  }
}
