import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';
import 'dart:convert';
import 'dart:core';


/* A simple web server that responds to **ALL** GET requests by returning
 * the contents of data.json file, and responds to ALL **POST** requests
 * by overwriting the contents of the data.json file
 *
 * Browse to it using http://localhost:8080
 *
 * Provides CORS headers, so can be accessed from any other page
 */

final HOST = "localhost"; // eg: localhost
final PORT = 1990;
String path = "";

void main() {
  HttpServer.bind(HOST, PORT).then((server) {
    server.listen((HttpRequest request) {
      switch (request.method) {
        case "GET":
          handleGet(request);
          break;
        case "POST":
          handlePost(request);
          break;
        case "OPTIONS":
          handleOptions(request);
          break;
        default: defaultHandler(request);
      }
    },
    onError: printError);

    print("Listening for GET and POST on http://$HOST:$PORT");
  },
  onError: printError);
}

/**
 * Handle GET requests by reading the contents of data.json
 * and returning it to the client
 */
void handleGet(HttpRequest req) {
  HttpResponse res = req.response;
  RegExp regex = new RegExp("([^?=&]+)(=([^&]*))?");
  print("${req.method}: ${req.uri.path}");
  String data_file = path + req.uri.path.substring(1,req.uri.path.length) + ".json";
  addCorsHeaders(res);

  if(req.uri.path == "/mongodbquery"){


    String queryStr = req.uri.query;
    var matches = regex.allMatches(queryStr);
    var collection = matches.elementAt(0).group(0);
    collection = collection.substring(collection.indexOf("=")+1);
    var database = matches.elementAt(1).group(0);
    database = database.substring(database.indexOf("=")+1);
    var query = matches.elementAt(2).group(0);
    queryStr = Uri.decodeComponent(query);
    queryStr = queryStr.substring(queryStr.indexOf("=")+1);
    List mongodb = new List();
    Db db = new Db(database);
    DbCollection coll;
    ObjectId id;
    db.open().then((c){
      print('connection open');
      coll = db.collection(collection);
      res.headers.add(HttpHeaders.CONTENT_TYPE, "application/json");
      try {

        print(JSON.decode(queryStr));
        Cursor cursor = coll.find(JSON.decode(queryStr));
        cursor.forEach((Map v) {

          //the mongo-dart ObjectId isn't supported by the JSON.encode()
          //so we'll just extract it, convert it to a string, and put it back again.
          var id = v["_id"];
          v.remove("_id");
          v["_id"] = id.toString();

          //finally, add the post to the list of mongodb.
          mongodb.add(v);

        }).then((dummy) {
          res.statusCode = HttpStatus.OK;
          res.write(JSON.encode(mongodb));
          res.close();
        });
      } catch (e){
        var err = "Error retrieving data from MongoDB";
        res.statusCode = HttpStatus.NO_CONTENT;
        res.write(err);
        res.close();
        print(err);
      }
      return;
    });

    return;
  }

  var file = new File(data_file);
  if (file.existsSync()) {
    res.headers.add(HttpHeaders.CONTENT_TYPE, "application/json");
    file.readAsBytes().asStream().pipe(res); // automatically close output stream
  }
  else {
    var err = "Could not find file: $data_file";
    res.write(err);
    res.close();
  }

}

/**
 * Handle POST requests by overwriting the contents of data.json
 * Return the same set of data back to the client.
 */
void handlePost(HttpRequest req) {
  HttpResponse res = req.response;
  print("${req.method}: ${req.uri.path}");
  String data_file = path + req.uri.path.substring(1,req.uri.path.length) + ".json";
  BytesBuilder builder = new BytesBuilder();

  addCorsHeaders(res);

  req.listen((List<int> buffer) {
    builder.add(buffer);

    if(req.uri.path == "/login"){
      var data = new String.fromCharCodes(buffer);
      print(data);
      res.close();
    }
    var file = new File(data_file);
    var ioSink = file.openWrite(); // save the data to the file
    ioSink.add(buffer);
    ioSink.close();

    // return the same results back to the client
    res.add(buffer);
    res.close();
  },
  onError: printError);

}

/**
 * Add Cross-site headers to enable accessing this server from pages
 * not served by this server
 *
 * See: http://www.html5rocks.com/en/tutorials/cors/
 * and http://enable-cors.org/server.html
 */
void addCorsHeaders(HttpResponse res) {
  res.headers.add("Access-Control-Allow-Origin", "*");
  res.headers.add("Access-Control-Allow-Methods", "POST, GET, OPTIONS");
  res.headers.add("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
}

void handleOptions(HttpRequest req) {
  HttpResponse res = req.response;
  addCorsHeaders(res);
  print("${req.method}: ${req.uri.path}");
  res.statusCode = HttpStatus.NO_CONTENT;
  res.close();
}

void defaultHandler(HttpRequest req) {
  HttpResponse res = req.response;
  addCorsHeaders(res);
  res.statusCode = HttpStatus.NOT_FOUND;
  res.write("Not found: ${req.method}, ${req.uri.path}");
  res.close();
}

void printError(error) => print(error);