import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:loading_indicator/loading_indicator.dart';

class WordPage extends StatefulWidget {
  String word;
  WordPage(this.word);
  @override
  State<StatefulWidget> createState() {
    return WordPageState(word);
  }
}

class WordPageState extends State<WordPage> {
  String word;

  int currentPage = 1;

  WordPageState(this.word) {
    fetchData();
  }

  bool isReady = false;
  bool loadingMore = true;
  var _data = {};

  void fetchData({int page: 1}) {
    var url = "https://www.arabdict.com/en/deutsch-arabisch/" +
        word +
        "/" +
        (page > 1 ? page.toString() : "");

    print(Uri.parse(url));

    http.Client().get(Uri.parse(url)).then((value) {
      print("downloaded.");

      var tree = parse(value.body);

      var data = {};

      // Pages
      try {
        var pages = tree.getElementsByClassName("pagination")[0].children;
        pages.removeAt(0); // «
        pages.removeLast(); // »
        _data["pages"] = pages.length;
      } catch (e) {
        _data["pages"] = 0;
      }

      // All possible results. (Lists)
      // entries -> $num > [{...}]
      if (_data["lists"] == null) {
        _data["lists"] = [];
      }
      tree.getElementsByClassName("results-items").forEach((element) {
        var list = [];
        element.getElementsByTagName("li").forEach((element) {
          var entrie = {};

          // Article
          try {
            var article = element.getElementsByClassName("article")[0].text;

            entrie["article"] = article;
            var color = Colors.grey;
            switch (article) {
              case "die":
                color = Colors.red;
                break;
              case "der":
                color = Colors.blue;
                break;
              case "das":
                color = Colors.green;
                break;
            }
            entrie["article-color"] = color;
          } catch (e) {}

          // Arabic
          try {
            var ar = element.getElementsByClassName("arabic")[0];

            try {
              var arabicTerm =
                  ar.getElementsByClassName("arabic-term")[0].text.trim();

              if (arabicTerm.isNotEmpty) {
                entrie["arabic-term"] = arabicTerm;
              }
            } catch (e) {}

            try {
              var arabicInfo =
                  ar.getElementsByClassName("term-info")[0].text.trim();

              if (arabicInfo.isNotEmpty) {
                entrie["arabic-info"] = arabicInfo;
              }
            } catch (e) {}
          } catch (e) {}

          // Latin
          try {
            var latin = element.getElementsByClassName("latin")[0];

            try {
              var latinTerm =
                  latin.getElementsByClassName("latin-term")[0].text.trim();

              if (latinTerm.isNotEmpty) {
                entrie["latin-term"] = latinTerm;
              }
            } catch (e) {}

            try {
              var latinInfo =
                  latin.getElementsByClassName("term-info")[0].text.trim();

              if (latinInfo.isNotEmpty) {
                entrie["latin-info"] = latinInfo;
              }
            } catch (e) {}
          } catch (e) {}

          list.add(entrie);
        });
        _data["lists"].add(list);
      });

      //TODO: examples.

      // Do You Mean?
      try {
        _data["doyoumean"] = [];
        tree
            .getElementsByClassName("doyoumean")[0]
            .getElementsByTagName("a")
            .forEach((element) {
          _data["doyoumean"].add(element.text);
        });
      } catch (e) {}

      setState(() {
        isReady = true;
        loadingMore = false;
        currentPage = page;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              BackButton(
                onPressed: () => Navigator.pop(context),
              ),
              Text(word),
            ],
          ),
        ),
        body: isReady
            ? ListView(
                children: [
                  Wrap(
                    // Do you mean?
                    children: [
                      ..._data["doyoumean"].map((item) {
                        return Container(
                            margin: EdgeInsets.all(5),
                            child: ElevatedButton(
                                onPressed: () {
                                  print(word);
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              new WordPage(item)));
                                },
                                child: Text(item)));
                      }).toList()
                    ],
                  ),
                  ..._data["lists"].map((list) {
                    return Column(
                      children: [
                        ...list.map((entrie) {
                          // TODO: add more info ... (plural)
                          return Container(
                              padding: EdgeInsets.all(10),
                              child: Column(children: [
                                Row(children: [
                                  entrie["article"] != null
                                      ? Text(
                                          entrie["article"],
                                          style: TextStyle(
                                            color: entrie["article-color"],
                                            fontFamily: "Harmattan",
                                            fontSize: 20,
                                          ),
                                        )
                                      : Text(""),
                                  entrie["latin-term"] != null
                                      ? Expanded(
                                          child: Text(
                                          entrie["latin-term"],
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontFamily: "Harmattan",
                                              fontSize: 20),
                                        ))
                                      : Text(""),
                                  entrie["latin-info"] != null
                                      ? Text(
                                          entrie["latin-info"],
                                          style: TextStyle(color: Colors.grey),
                                        )
                                      : Text(""),
                                  entrie["arabic-info"] != null
                                      ? Text(
                                          entrie["arabic-info"],
                                          style: TextStyle(color: Colors.grey),
                                        )
                                      : Text(""),
                                  entrie["arabic-term"] != null
                                      ? Expanded(
                                          child: Text(
                                          entrie["arabic-term"],
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontFamily: "Harmattan",
                                              fontSize: 20),
                                        ))
                                      : Text(""),
                                ]),
                                Row(
                                  children: [],
                                )
                              ]));
                        }).toList(),
                        // TODO: remove divider when there is no more.
                        Divider(
                          color: Colors.blue,
                          thickness: 3,
                          height: 10,
                        )
                      ],
                    );
                  }).toList(),

                  // Check if there is more.
                  _data["pages"] > currentPage
                      ? Container(
                          margin: EdgeInsets.all(10),
                          padding: EdgeInsets.all(10),
                          child: ElevatedButton(
                            child: Text("load more"),
                            onPressed: loadingMore
                                ? null
                                : () {
                                    setState(() {
                                      loadingMore = true;
                                      fetchData(page: currentPage + 1);
                                    });
                                  },
                          ),
                        )
                      : Container(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.not_interested_outlined),
                        )
                ],
              )
            : Center(
                child: Container(
                  width: 50,
                  child: LoadingIndicator(
                    indicatorType: Indicator.ballSpinFadeLoader,
                  ),
                ),
              ),
      ),
    );
  }
}
