import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'constants.dart';

// TODO: see https://blog.waldo.io/graphql-in-flutter/ for runMutation example
void main() async {
  // We're using HiveStore for persistence,
  // so we need to initialize Hive.
  await initHiveForFlutter();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final HttpLink urlLink = HttpLink(kParseApiUrl, defaultHeaders: {
      'X-Parse-Application-Id': kParseApplicationId,
      'X-Parse-Client-Key': kParseClientKey,
//      'X-Parse-Session-Token': 'r:8e26ccce46ec4650cc79e2b969c50674'
    });
    final authLink = AuthLink(
      // ignore: undefined_identifier
      getToken: () async => 'Bearer r:8e26ccce46ec4650cc79e2b969c50674',
    );

    var httpLink = authLink.concat(urlLink);

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

  static String query = '''
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

  ///THIS IS A SAMPLE FOR MAKING MUTABLE REQUEST

  static String loginQuery = '''
    mutation LogIn{
      logIn(input: {
        username: "test",
        password: "testtest"
      }){
        viewer{
          sessionToken
          user { 
           objectId
           id
           emailVerified
          }
        }
      }
    }
    ''';

/////// check https://blog.logrocket.com/using-graphql-with-flutter-a-tutorial-with-examples/
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
                      title: Text(result.data["heroes"]["edges"][index]["node"]
                          ['name']),
                      subtitle: Text("height : " +
                          result.data["heroes"]["edges"][index]["node"]
                                  ['height']
                              .toString()),
                    );
                  },
                  itemCount: result.data["heroes"]["edges"].length,
                );
              }
            },
          ),
          floatingActionButton: Mutation(
              options: MutationOptions(
                  document: gql(loginQuery),
                  update: (GraphQLDataProxy cache, QueryResult result) {
                    return cache;
                  },
                  onCompleted: (dynamic resultData) {
                    String _token =
                        resultData['logIn']['viewer']['sessionToken'];
                    print("TOKEN:" + _token);
                    // TODO implement this: https://github.com/zino-hofmann/graphql-flutter/issues/363
                  }),
              builder: (
                RunMutation runMutation,
                QueryResult result,
              ) {
                return FloatingActionButton(
                  onPressed: () =>
                      runMutation({"username": "test", "password": "testtest"}),
                  tooltip: 'Login',
                  child: const Icon(Icons.login_sharp),
                );
              })),
    );
  }
}
