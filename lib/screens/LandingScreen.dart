import 'package:beanbot_app/utils/widget_functions.dart';
import 'package:flutter/material.dart';

class LandingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final ThemeData themeData = Theme.of(context);
    const double padding = 25;
    final sidePadding = EdgeInsets.symmetric(horizontal: padding);

    return SafeArea(
      child: Scaffold(
          body: SizedBox(
        width: size.width,
        height: size.height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            addVerticalSpace(padding),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: padding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "BeanBot",
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color.fromRGBO(47, 140, 86, 1)),
                  ),
                  Icon(
                    Icons.tune,
                    color: Color.fromRGBO(47, 140, 86, 1),
                  )
                ],
              ),
            ),
            addVerticalSpace(40),
            // Padding(
            //   padding: sidePadding,
            //   child: Text("Silo 1 (grammes)",
            //       style: TextStyle(
            //           color: Colors.black54, fontWeight: FontWeight.bold)),
            // ),
            // addVerticalSpace(8),
            // Padding(
            //     padding: sidePadding,
            //     child: TextField(
            //         keyboardType: TextInputType.number,
            //         style: const TextStyle(
            //             color: Color.fromRGBO(47, 140, 86, 0.7)),
            //         decoration: InputDecoration(
            //           border: OutlineInputBorder(
            //               borderRadius: BorderRadius.circular(5),
            //               borderSide: BorderSide.none),
            //           filled: true,
            //           fillColor: const Color.fromRGBO(47, 140, 86, 0.1),
            //         ))),
            // addVerticalSpace(padding),
            Padding(
                padding: sidePadding,
                child: ElevatedButton(
                    onPressed: () {},
                    child: Text("Place order"),
                    style: ElevatedButton.styleFrom(
                        primary: Color.fromRGBO(47, 140, 86, 1),
                        minimumSize: Size.fromHeight(50)))),
          ],
        ),
      )),
    );
  }
}
