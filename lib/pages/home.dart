import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:band_names/models/band.dart';
import 'package:provider/provider.dart';

import 'package:pie_chart/pie_chart.dart';

import 'package:band_names/services/socket_service.dart';


class HomePage extends StatefulWidget {

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  List<Band> bands = [
    // Band(id: '1', name: 'Metallica', votes: 5),
    // Band(id: '2', name: 'Queen', votes: 1),
    // Band(id: '3', name: 'Héroes del Silencio', votes: 2),
    // Band(id: '4', name: 'Bon Jovi', votes: 5),
  ];

  @override
  void initState() { 
    
    final socketService = Provider.of<SocketService>(context, listen: false);

    socketService.socket.on('active-bands', _handleActiveBands );

    super.initState();
    
  }

  _handleActiveBands( dynamic payload ) {
    this.bands = (payload as List)
          .map( (band) => Band.fromMap(band) )
          .toList();

      setState(() {});
  }

  @override
  void dispose() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.socket.off('active-bands');

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final socketService = Provider.of<SocketService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('BandNames', style: TextStyle( color: Colors.black87 ),),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: <Widget>[
          Container(
            margin: EdgeInsets.only( right: 10 ),
            child: ( socketService.serverStatus == ServerStatus.Online )
              ? Icon( Icons.check_circle, color: Colors.blue[300],)
              : Icon( Icons.offline_bolt, color: Colors.red,),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[

          _showGraph(),

          Expanded(
            child: ListView.builder(
              itemCount: bands.length,
              itemBuilder: ( context, i ) =>_bandTile( bands[i] ),
            ),
          )

        ],
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 1,
        child: Icon( Icons.add ),
        onPressed: addNewBand,
      ),
    );
  }

  Widget _bandTile( Band band ) {

    final socketService = Provider.of<SocketService>(context, listen: false);

    return Dismissible(
      key: Key(band.id),
      direction: DismissDirection.startToEnd,
      onDismissed: ( _ ) => socketService.emit('delete-band', { 'id': band.id }),
      background: Container(
        padding: EdgeInsets.only( left: 8.0 ),
        color: Colors.red,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('Delete Band', style: TextStyle( color: Colors.white ),),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          child: Text( band.name.substring(0,2) ),
          backgroundColor: Colors.blue[100],
        ),
        title: Text( band.name ),
        trailing: Text( '${ band.votes }', style: TextStyle( fontSize: 20 ), ),
        onTap: () => socketService.socket.emit('vote-band', { 'id': band.id }),
      ),
    );
  }

  addNewBand() {

    final textController = new TextEditingController();

    if ( Platform.isAndroid ) {
      showDialog(
        context: context,
        builder: ( _ ) => AlertDialog(
            title: Text('New band name:'),
            content: TextField(
              controller: textController,
            ),
            actions: <Widget>[
              MaterialButton(
                child: Text('Add'),
                elevation: 5,
                textColor: Colors.blue,
                onPressed: () => addBandToList( textController.text ),
              ),
            ],
          )
      );
    }

    showCupertinoDialog(
      context: context, 
      builder: (_) => CupertinoAlertDialog(
          title: Text('New band name:'),
          content: CupertinoTextField(
            controller: textController,
          ),
          actions: <Widget>[

            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text('Add'),
              onPressed: () => addBandToList( textController.text ),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: Text('Dismiss'),
              onPressed: () => Navigator.pop(context),
            ),

          ],
        )
    );


  }

  void addBandToList( String name ) {

    // print( name );

    if ( name.length > 1 ) {
      // Podemos agregar
      // this.bands.add( new Band(id: DateTime.now().toString(), name: name, votes: 0 ));
      // setState(() {});

      // Emitir: add-band
      // { name: name }

      final socketService = Provider.of<SocketService>(context, listen: false);
      socketService.emit('add-band', { 'name': name });

    }

    Navigator.pop(context);

  }

  // Mostrar gráfica
  Widget _showGraph() {

    Map<String, double> dataMap = new Map();

    bands.forEach((band) {
      dataMap.putIfAbsent(band.name, () => band.votes.toDouble()) ;
    });

    final List<Color> colorList = [
      Colors.blue[50],
      Colors.blue[200],
      Colors.pink[50],
      Colors.pink[200],
      Colors.yellow[50],
      Colors.yellow[200],
    ];

    return Container(
      padding: EdgeInsets.only( top: 20 ),
      width: double.infinity,
      height: 200,
      child: PieChart(
        dataMap: dataMap,
        animationDuration: Duration(milliseconds: 800),
        chartLegendSpacing: 32,
        chartRadius: MediaQuery.of(context).size.width / 2.2,
        colorList: colorList,
        initialAngleInDegree: 0,
        chartType: ChartType.ring,
        ringStrokeWidth: 22,
        // centerText: "HYBRID",
        legendOptions: LegendOptions(
          showLegendsInRow: false,
          legendPosition: LegendPosition.right,
          showLegends: true,
          legendShape: BoxShape.circle,
          legendTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        chartValuesOptions: ChartValuesOptions(
          showChartValueBackground: true,
          showChartValues: true,
          showChartValuesInPercentage: true,
          showChartValuesOutside: false,
          decimalPlaces: 0,
        ),
      )
    );
  }


}