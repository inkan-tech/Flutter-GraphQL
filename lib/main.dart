
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'constants.dart';

void main() async {
  // We're using HiveStore for persistence,
  // so we need to initialize Hive.
  await initHiveForFlutter();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final HttpLink httpLink =
        HttpLink(kParseApiUrl, 
        defaultHeaders: {
      'X-Parse-Application-Id': kParseApplicationId,
      'X-Parse-Client-Key': kParseClientKey
    });

      // 'X-Parse-REST-API-Key': kParseRestApiKey
    ValueNotifier<GraphQLClient> client = ValueNotifier(
      GraphQLClient(
        cache: GraphQLCache(store: HiveStore()),
        link: httpLink,
      ),
    );

    return MaterialApp(
      home: GraphQLProvider(
        child: MyHomePage(),
        client: client,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String name;
  String saveFormat;
  String objectId;

  String query = '''
  query FindHero {
    heroes{
      count,
      edges{
        node{
          name
          height
        }
      }
    }
  }
  ''';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Parsing data using GraphQL',
          ),
        ),
        body: Query(
          options: QueryOptions(
            document: gql(query),
          ),
          builder: (
            QueryResult result, {
            Refetch refetch,
            FetchMore fetchMore,
          }) {
            print(result.exception);
            if (result.data == null) {
              return Center(
                  child: Text(
                "Loading...",
                style: TextStyle(fontSize: 20.0),
              ));
            } else {
              return ListView.builder(
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                    title: Text(result.data["heroes"]["edges"]
                        [index]["node"]['name']),
                    subtitle: Text("height : "+result.data["heroes"]["edges"]
                        [index]["node"]['height'].toString())
                        ,
                  );
                },
                itemCount: result.data["heroes"]["edges"].length,
              );
            }
          },
        ),
      ),
    );
  }
}
