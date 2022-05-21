import 'dart:ui';

import 'package:beanbot_app/utils/widget_functions.dart';
import "package:flutter/material.dart";
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:charts_flutter/flutter.dart' as charts;

// Functional Config
const int STEP_SIZE = 10;

// Style Config
const Color COLOR_LIGHT_GREEN = Color.fromRGBO(27, 202, 148, 1);
const Color COLOR_DARK_GREEN = Color.fromRGBO(47, 140, 86, 1);
const Color COLOR_PURPLE = Color.fromRGBO(124, 79, 252, 1);
const double padding = 20.0;

String slagzin = "Supported By Tom Boonen";

class MainScreen extends StatefulWidget {
  final String deviceName;
  String deviceStatus;
  bool order_complete;
  final bool isConnected;
  BluetoothConnection? connection;
  Function order_create;
  List<int> real_weights;
  List<int> desired_weights;
  Function close_popup;

  MainScreen(
      {Key? key,
      required this.deviceName,
      required this.deviceStatus,
      required this.isConnected,
      required this.connection,
      required this.order_create,
      required this.order_complete,
      required this.real_weights,
      required this.desired_weights,
      required this.close_popup})
      : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<int> weights = [0, 0, 0];

  @override
  void reassemble() {
    print("Close");
    setState(() {
      weights = [0, 0, 0];
    });
    super.reassemble();
  }

  void changeWeightBySteps(int step, int silo) {
    if (weights[silo] + step >= 0) {
      setState(() {
        weights[silo] = weights[silo] + step;
      });
    }
  }

  void changeWeight(int newWeight, int silo) {
    if (newWeight >= 0) {
      setState(() {
        weights[silo] = newWeight;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: padding),
        child: Column(children: <Widget>[
          if (widget.isConnected && !widget.order_complete) ...[
            MainMenu(),
            ConnectedDeviceStatus(
              deviceName: widget.deviceName,
              deviceStatus: widget.deviceStatus,
            ),
            addVerticalSpace(padding),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Create order (g)",
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: COLOR_DARK_GREEN),
              ),
            ),
            WeightInput(
              silo: 0,
              weight: weights[0],
              changeWeightByStepsHandler: changeWeightBySteps,
              changeWeightHandler: changeWeight,
            ),
            WeightInput(
              silo: 1,
              weight: weights[1],
              changeWeightByStepsHandler: changeWeightBySteps,
              changeWeightHandler: changeWeight,
            ),
            WeightInput(
              silo: 2,
              weight: weights[2],
              changeWeightByStepsHandler: changeWeightBySteps,
              changeWeightHandler: changeWeight,
            ),
            addVerticalSpace(padding),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(padding),
                  primary: COLOR_PURPLE,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: const Text(
                "Submit Order",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              onPressed: () {
                widget.order_create(weights);
                setState(() {
                  weights = [0, 0, 0];
                });
              },
            )
          ],
          if (widget.isConnected && widget.order_complete) ...[
            addVerticalSpace(padding * 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Order Complete",
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: COLOR_DARK_GREEN),
                ),
                GestureDetector(
                  child: Icon(Icons.close),
                  onTap: () => widget.close_popup(),
                )
              ],
            ),
            addVerticalSpace(padding),
            OrderCompleteCard(
              desired_weights: widget.desired_weights,
              real_weights: widget.real_weights,
            )
          ],
          if (!widget.isConnected) ...[
            MainMenu(),
            const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Connecting to the beanbot...",
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                      fontWeight: FontWeight.w300),
                ))
          ]
        ]),
      ),
    ));
  }
}

class OrderSeries {
  final int silo;
  final int weight;

  OrderSeries({
    required this.silo,
    required this.weight,
  });
}

class OrderCompleteCard extends StatelessWidget {
  List<int> real_weights;
  List<int> desired_weights;

  OrderCompleteCard(
      {Key? key, required this.real_weights, required this.desired_weights})
      : super(key: key);

  // List<int> real_weights = [123, 164, 432];
  // List<int> desired_weights = [125, 160, 420];

  @override
  Widget build(BuildContext context) {
    List<charts.Series<OrderSeries, String>> series = [
      charts.Series<OrderSeries, String>(
          id: "Desired",
          domainFn: (OrderSeries data, _) => "Type ${data.silo}",
          measureFn: (OrderSeries data, _) => data.weight,
          colorFn: (OrderSeries data, _) =>
              charts.ColorUtil.fromDartColor(COLOR_LIGHT_GREEN),
          data: List<OrderSeries>.generate(
              desired_weights.length,
              (int index) => OrderSeries(
                  silo: index + 1, weight: desired_weights[index]))),
      charts.Series<OrderSeries, String>(
          id: "Real",
          domainFn: (OrderSeries data, _) => "Type ${data.silo}",
          measureFn: (OrderSeries data, _) => data.weight,
          colorFn: (OrderSeries data, _) =>
              charts.ColorUtil.fromDartColor(COLOR_PURPLE),
          data: List<OrderSeries>.generate(
              desired_weights.length,
              (int index) =>
                  OrderSeries(silo: index + 1, weight: real_weights[index]))),
    ];

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: charts.BarChart(series,
              animate: true,
              barGroupingType: charts.BarGroupingType.grouped,
              behaviors: [new charts.SeriesLegend()]),
        ),
        ...List.generate(
          desired_weights.length,
          (index) => Column(
            children: [
              addVerticalSpace(padding),
              Container(
                  padding: const EdgeInsets.all(padding),
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            spreadRadius: 0,
                            blurRadius: 10,
                            offset: const Offset(1, 1))
                      ]),
                  child: Column(
                    children: [
                      Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Type ${index + 1}",
                            style: const TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 16),
                          )),
                      addVerticalSpace(padding / 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  "${desired_weights[index]}g",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: COLOR_LIGHT_GREEN,
                                      fontSize: 28),
                                ),
                                const Text(
                                  " → ",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 28,
                                      color: Colors.black26),
                                ),
                                Text(
                                  "${real_weights[index]}g",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: COLOR_PURPLE,
                                      fontSize: 28),
                                ),
                              ]),
                          Text(
                            "${desired_weights[index] == 0 ? 0 : (real_weights[index] / desired_weights[index] * 1000 - 1000).toInt() / 10}%",
                            style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Colors.black26,
                                fontSize: 16),
                          ),
                        ],
                      )
                    ],
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

class MainMenu extends StatelessWidget {
  const MainMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: padding),
      child: Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "BeanBot",
                style: TextStyle(
                    color: COLOR_DARK_GREEN,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    height: 1),
              ),
              Text(
                // "Supported by Tom Boonen",
                slagzin,
                style: const TextStyle(
                    color: COLOR_LIGHT_GREEN,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1),
              )
            ],
          )),
    );
  }
}

class ConnectedDeviceStatus extends StatelessWidget {
  final String deviceName;
  final String deviceStatus;
  const ConnectedDeviceStatus(
      {Key? key, required this.deviceName, required this.deviceStatus})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      width: double.infinity,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10), color: COLOR_LIGHT_GREEN),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "Connected Device",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ],
          ),
          addVerticalSpace(4),
          Row(
            children: [
              const Text(
                "name:",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1),
              ),
              addHorizontalSpace(10),
              Text(
                deviceName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "status:",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1),
              ),
              addHorizontalSpace(10),
              Flexible(
                child: Text(
                  deviceStatus,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      height: 1),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class WeightInput extends StatelessWidget {
  final int weight;
  final int silo;
  final Function changeWeightByStepsHandler;
  final Function changeWeightHandler;
  final TextEditingController customController = TextEditingController();

  WeightInput(
      {Key? key,
      required this.weight,
      required this.changeWeightByStepsHandler,
      required this.changeWeightHandler,
      required this.silo})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Custom Controller for the input
    customController.text = "$weight";
    customController.selection = TextSelection.fromPosition(
        TextPosition(offset: customController.text.length));

    return Column(
      children: [
        addVerticalSpace(padding),
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(padding),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        spreadRadius: 0,
                        blurRadius: 10,
                        offset: const Offset(1, 1))
                  ]),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (text) {
                        try {
                          int newWeight = int.parse(text);
                          changeWeightHandler(newWeight, silo);
                        } catch (error) {
                          return;
                        }
                      },
                      keyboardType: TextInputType.number,
                      controller: customController,
                      style: const TextStyle(
                          fontSize: 40, fontWeight: FontWeight.w900),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.all(0),
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Row(
                    children: [
                      addHorizontalSpace(padding),
                      ElevatedButton(
                          onPressed: () =>
                              changeWeightByStepsHandler(-STEP_SIZE, silo),
                          child: const Text(
                            "-",
                            style: TextStyle(
                                fontSize: 48, fontWeight: FontWeight.w900),
                          ),
                          style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              minimumSize: const Size(48, 48),
                              primary: COLOR_LIGHT_GREEN)),
                      addHorizontalSpace(padding),
                      ElevatedButton(
                          onPressed: () =>
                              changeWeightByStepsHandler(STEP_SIZE, silo),
                          child: const Text(
                            "+",
                            style: TextStyle(
                                fontSize: 48, fontWeight: FontWeight.w900),
                          ),
                          style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              minimumSize: const Size(48, 48),
                              primary: COLOR_LIGHT_GREEN)),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              child: SizedBox(
                  width: 48,
                  height: 48,
                  child: DecoratedBox(
                    child: Center(
                        child: Text(
                      "${silo + 1}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          height: 1.1,
                          fontWeight: FontWeight.w900),
                    )),
                    decoration: const BoxDecoration(
                        color: COLOR_PURPLE,
                        borderRadius: BorderRadius.all(Radius.circular(24))),
                  )),
              transform: Matrix4.translationValues(-12, -12, 0),
            ),
          ],
        ),
      ],
    );
  }
}
