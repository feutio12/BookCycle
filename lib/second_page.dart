import 'package:flutter/material.dart';
class SecondPage extends StatelessWidget {
  const SecondPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.pinkAccent,foregroundColor: Colors.white,
        title: Text("Second Page",
          style: TextStyle(
              fontWeight: FontWeight.bold, fontFamily: "Poppins"
          ),
        ),centerTitle: true,
      ),

      body: Column(
        children: [
          ListTile(
            leading: Image.asset("assets/images/ccc.jpg"),
            title: Text("Christine"),
            subtitle: Text("See you in house"),
            trailing: Text("22h30"),
          ),ListTile(
            leading: Image.asset("assets/images/ccc.jpg"),
            title: Text("Eloge"),
            subtitle: Text("Yo"),
            trailing: Text("20h19"),
          ),ListTile(
            leading: Image.asset("assets/images/ccc.jpg"),
            title: Text("Eloge"),
            subtitle: Text("Yo"),
            trailing: Text("20h19"),
          ),ListTile(
            leading: Image.asset("assets/images/ccc.jpg"),
            title: Text("Eloge"),
            subtitle: Text("Yo"),
            trailing: Text("20h19"),
          ),ListTile(
            leading: Image.asset("assets/images/ccc.jpg"),
            title: Text("Eloge"),
            subtitle: Text("Yo"),
            trailing: Text("20h19"),
          ),ListTile(
            leading: Image.asset("assets/images/ccc.jpg"),
            title: Text("Eloge"),
            subtitle: Text("Yo"),
            trailing: Text("20h19"),
          ),ListTile(
            leading: Image.asset("assets/images/ccc.jpg"),
            title: Text("Eloge"),
            subtitle: Text("Yo"),
            trailing: Text("20h19"),
          )


        ],
      ),
    );
  }
}