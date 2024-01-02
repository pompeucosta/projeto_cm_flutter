import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:run_route/data/blocs/bottom_navigation/bottom_navigation_bloc.dart';
import 'package:run_route/data/blocs/running_session/running_session_bloc.dart';
import 'package:run_route/data/blocs/sessions/sessions_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'camera_preview_screen.dart';

import 'data/blocs/camera_cubit.dart';
import 'package:camera/camera.dart';

import 'package:geolocator/geolocator.dart';

import 'package:intl/intl.dart';

class RunningSessionScreen extends StatelessWidget {
  const RunningSessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: RunningSessionView()
    );
  }
}

class RunningSessionView extends StatelessWidget {
  const RunningSessionView({super.key});

  @override
  Widget build(BuildContext context) {
    MapController mapControl = MapController(); 
    return BlocConsumer<RunningSessionBloc, RunningSessionState>(
        listener: (context, state) {
      switch (state.status) {
        case RunningSessionStatus.failure:
          break;
        case RunningSessionStatus.inProgress:
          break;
        case RunningSessionStatus.initial:
          break;
        case RunningSessionStatus.paused:
          break;
        case RunningSessionStatus.success:
          break;
        case RunningSessionStatus.ended:
          context.read<SessionsBloc>().add(const GetSessionsEvent());
          context.read<BottomNavigationBloc>().add(const SessionEndedEvent());
          break;
      }
    }, builder: (context, state) {
      return Column(
        children: [
          MyMap(state,mapControl),
          DetailsContainer(state), 
        ],
      );
    }, buildWhen: (previous, current) {
      return current.status == RunningSessionStatus.inProgress ||
          current.status == RunningSessionStatus.paused;
    });
  }
}

class MyMap extends StatelessWidget {
  final RunningSessionState state;
  final MapController mapControl;
  const MyMap(this.state, this.mapControl, {super.key});


  @override
  Widget build(BuildContext context) {

    LatLng currentPosition = const LatLng(40.63311541916194, -8.659546357913722);
    if (state.coordinates.isNotEmpty) {
      Position lastPosition = state.coordinates.last;
      currentPosition = LatLng(lastPosition.latitude, lastPosition.longitude);
    
      List<LatLng> coordinatesAsLatLng = <LatLng>[];
      for (Position element in state.coordinates) {
        coordinatesAsLatLng.add(LatLng(element.latitude, element.longitude));
      }
      mapControl.fitCamera(CameraFit.coordinates(coordinates: coordinatesAsLatLng, maxZoom: 17, padding: const EdgeInsets.all(50)));
    }

    

    return Flexible(
        child: FlutterMap(
              mapController: mapControl,
              options: MapOptions(
                initialCenter: currentPosition,
                initialZoom: 9.2,
                
              ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.app',
        ),
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
              'OpenStreetMap contributors',
              onTap: () =>
                  launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
            ),
          ],
        ),
      ],
    ));
  }
}

class DetailsContainer extends StatelessWidget {
  DetailsContainer(this.state, {super.key});
  final ExpansionTileController controller = ExpansionTileController();
  final DateTime sessionStartTime = DateTime.now();
  final RunningSessionState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height),
          child: ExpansionTile(
          initiallyExpanded: true,
          controller: controller,
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Session Details',
              )
            ],
          ),
          children: [
            Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height - 150),
              child: ListView(
                shrinkWrap: true,
                children: [
                  Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
                    child: SessionDetails(state),
                  ),
                  const Divider(),
                  Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
                    child: SessionButtons(state.status),
                  )
                  
                ],
              )
            )
          ],
        ),
    )],
    );
  }
}

class SessionDetails extends StatelessWidget {
  final RunningSessionState state;
  const SessionDetails(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    NumberFormat distanceFormat = NumberFormat("####0.0##");
    NumberFormat speedFormat = NumberFormat("####0.0");
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SessionInfo(
              name: "Time:",
              info:
                  "${state.duration.inHours.toString().padLeft(2, '0')}:${(state.duration.inMinutes % 60).toString().padLeft(2, '0')}:${(state.duration.inSeconds % 60).toString().padLeft(2, '0')}",
            ),
            SessionInfo(
              name: "Average Speed:",
              info: "${speedFormat.format(state.averageSpeed)} km/h",
            ),
            SessionInfo(
              name: "Top Speed:",
              info: "${speedFormat.format(state.topSpeed)} km/h",
            ),
          ],
        ),
         Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SessionInfo(
              name: "Distance:",
              info: "${distanceFormat.format(state.distance)} m",
            ),
            SessionInfo(
              name: "Steps Taken:",
              info: "${state.stepsTaken}",
            ),
            SessionInfo(
              name: "Calories Burned:",
              info: "${distanceFormat.format(state.caloriesBurned/1000)} kcal",
            ),
          ],
        ),
      ],
    );
  }
}

class SessionButtons extends StatelessWidget {
  const SessionButtons(this.sessionStatus, {super.key});
  final RunningSessionStatus sessionStatus;

  void _goToCamera(BuildContext context) {
    CameraDescription camera = context.read<CameraCubit>().state;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CameraScreen(camera)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
                onPressed: () {
                  context
                      .read<RunningSessionBloc>()
                      .add(const PauseUnpauseSessionEvent());
                },
                icon: sessionStatus == RunningSessionStatus.inProgress
                    ? const Icon(Icons.pause)
                    : const Icon(Icons.play_arrow)),
            IconButton(
                onPressed: () {
                  _goToCamera(context);
                },
                icon: const Icon(Icons.camera_alt))
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton(
                child: const Text("Cancel"),
                onPressed: () {
                  context
                      .read<RunningSessionBloc>()
                      .add(const CancelSessionEvent());

                  context
                      .read<BottomNavigationBloc>()
                      .add(const SessionEndedEvent());
                }),
            TextButton(
                child: const Text("Finish"),
                onPressed: () {
                  context
                      .read<RunningSessionBloc>()
                      .add(const EndSessionEvent());
                }),
          ],
        ),
      ],
    );
  }
}

class SessionInfo extends StatelessWidget {
  const SessionInfo({super.key, required this.name, required this.info});

  final String name;
  final String info;

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              info,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ));
  }
}
