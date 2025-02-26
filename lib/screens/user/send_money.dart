import 'package:flutter/material.dart';

class SendMoneyScreen extends StatelessWidget {
  const SendMoneyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              // Row(
              //   children: [
              //     Container(
              //       decoration: BoxDecoration(
              //         color: Colors.grey[100],
              //         shape: BoxShape.circle,
              //       ),
              //       child: IconButton(
              //         icon: const Icon(Icons.arrow_back),
              //         onPressed: () {
              //           Navigator.pop(context);
              //         },
              //       ),
              //     ),
              //     const SizedBox(width: 16),
              //     const Text(
              //       'Send Money',
              //       style: TextStyle(
              //         fontSize: 20,
              //         fontWeight: FontWeight.bold,
              //       ),
              //     ),
              //   ],
              // ),
              // const SizedBox(height: 24),

              // // Credit Card
              // Container(
              //   padding: const EdgeInsets.all(24),
              //   decoration: BoxDecoration(
              //     color: const Color(0xFF1A1F71),
              //     borderRadius: BorderRadius.circular(16),
              //   ),
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       Row(
              //         mainAxisAlignment: MainAxisAlignment.end,
              //         children: [
              //           Icon(Icons.qr_code, size: 50, color: Colors.black),
              //           Transform.rotate(
              //               angle: 3.1416 / 2,
              //               child: Icon(Icons.wifi,
              //                   color: Colors.white.withOpacity(0.5))),
              //         ],
              //       ),
              //       const SizedBox(height: 24),
              //       const Text(
              //         '4562  1122  4595  7852',
              //         style: TextStyle(
              //           color: Colors.white,
              //           fontSize: 24,
              //           letterSpacing: 2,
              //         ),
              //       ),
              //       const SizedBox(height: 24),
              //       Row(
              //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //         children: [
              //           Column(
              //             crossAxisAlignment: CrossAxisAlignment.start,
              //             children: [
              //               Text(
              //                 'AR Jonson',
              //                 style: TextStyle(
              //                   color: Colors.white.withOpacity(0.9),
              //                   fontSize: 16,
              //                 ),
              //               ),
              //               const SizedBox(height: 4),
              //               Row(
              //                 children: [
              //                   Text(
              //                     'Expiry Date',
              //                     style: TextStyle(
              //                       color: Colors.white.withOpacity(0.5),
              //                       fontSize: 12,
              //                     ),
              //                   ),
              //                   const SizedBox(width: 16),
              //                   Text(
              //                     'CVV',
              //                     style: TextStyle(
              //                       color: Colors.white.withOpacity(0.5),
              //                       fontSize: 12,
              //                     ),
              //                   ),
              //                 ],
              //               ),
              //               Row(
              //                 children: [
              //                   const Text(
              //                     '24/2000',
              //                     style: TextStyle(
              //                       color: Colors.white,
              //                       fontSize: 14,
              //                     ),
              //                   ),
              //                   const SizedBox(width: 16),
              //                   const Text(
              //                     '6986',
              //                     style: TextStyle(
              //                       color: Colors.white,
              //                       fontSize: 14,
              //                     ),
              //                   ),
              //                 ],
              //               ),
              //             ],
              //           ),
              //           Image.network(
              //             'https://v0.dev/placeholder.svg',
              //             width: 60,
              //             height: 40,
              //           ),
              //         ],
              //       ),
              //     ],
              //   ),
              // ),
              // const SizedBox(height: 24),

              // Send to Section
              const Text(
                'Send to',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Add Button
                    Column(
                      children: [
                        GestureDetector(
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.blue),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add, color: Colors.blue),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('Add'),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Contact Avatars
                    ...['Yamilet', 'Alexa', 'Yakub', 'Krishna']
                        .map((name) => Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundImage: Image.asset(
                                      'assets/user.png',
                                    ).image,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(name),
                                ],
                              ),
                            ))
                        .toList(),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Amount Input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Enter Your Amount',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Change Currency?',
                            style: TextStyle(
                              color: Colors.pink,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: const [
                        Text(
                          'USD',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(width: 16),
                        Text(
                          '36.00',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Send Money Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    try {
                        Navigator.pushReplacementNamed(context, '/requestmoney');
                      } catch (e) {
                        // ignore: avoid_print
                        print('Error sign in -  Navigator.pushNamed(context, /requestmoney): $e');
                      }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Send Money',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
