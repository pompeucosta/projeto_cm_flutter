import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:run_route/data/blocs/bottom_navigation/bottom_navigation_bloc.dart';
import 'package:run_route/data/blocs/running_session/running_session_bloc.dart';
import 'data/blocs/presets/presets_bloc.dart';
import 'edit_preset_page.dart';
import 'data/models/preset.dart';

class ListCard extends StatelessWidget {
  final Preset preset;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ListCard(this.preset, this.onEdit, this.onDelete, {super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        final homeBloc = context.read<BottomNavigationBloc>();
        homeBloc.add(const SessionStartedEvent());
        context.read<RunningSessionBloc>().add(StartSessionEvent(preset));
      },
      style: TextButton.styleFrom(
        backgroundColor: Colors.transparent,
        side: BorderSide.none,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        padding: const EdgeInsets.all(0.0),
      ),
      child: Card(
        margin: const EdgeInsets.all(8.0),
        child: ListTile(
          title: Text(preset.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${preset.duration.inHours.toString().padLeft(2, '0')}:${(preset.duration.inMinutes % 60).toString().padLeft(2, '0')}:${(preset.duration.inSeconds % 60).toString().padLeft(2, '0')}",
              ),
              if (preset.twoWay) const Text("Two way"),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(onPressed: onEdit, icon: const Icon(Icons.edit)),
              IconButton(onPressed: onDelete, icon: const Icon(Icons.delete)),
            ],
          ),
        ),
      ),
    );
    // ElevatedButton(
    //   child: Card(
    //       margin: const EdgeInsets.all(8.0),
    //       child: ListTile(
    //         title: Text(preset.name),
    //         subtitle: Column(
    //           crossAxisAlignment: CrossAxisAlignment.start,
    //           children: [
    //             Text(
    //                 "${preset.duration.inHours.toString().padLeft(2, '0')}:${(preset.duration.inMinutes % 60).toString().padLeft(2, '0')}:${(preset.duration.inSeconds % 60).toString().padLeft(2, '0')}"),
    //             if (preset.twoWay) const Text("Two way"),
    //           ],
    //         ),
    //         trailing: Row(
    //           mainAxisSize: MainAxisSize.min,
    //           children: [
    //             IconButton(onPressed: onEdit, icon: const Icon(Icons.edit)),
    //             IconButton(onPressed: onDelete, icon: const Icon(Icons.delete))
    //           ],
    //         ),
    //       )),
    //   onPressed: () {
    //     final homeBloc = context.read<BottomNavigationBloc>();
    //     homeBloc.add(const SessionStartedEvent());
    //     context.read<RunningSessionBloc>().add(StartSessionEvent(preset));
    //     // homeBloc.add(TabChangedEvent(AppTab.session.index));
    //   },
    // );
  }
}

class PresetsPage extends StatelessWidget {
  const PresetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PresetsView();
  }
}

class PresetsView extends StatelessWidget {
  const PresetsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PresetsBloc, PresetsOverviewState>(
      listener: (context, state) {
        switch (state.status) {
          case PresetsOverviewStatus.loading:
            break;
          case PresetsOverviewStatus.success:
            break;
          case PresetsOverviewStatus.failure:
            break;
          case PresetsOverviewStatus.initial:
            context.read<PresetsBloc>().add(LoadPresetsEvent());
            break;
          case PresetsOverviewStatus.loaded:
            break;
        }
      },
      builder: (context, state) {
        if (state.presets != null) {
          return PresetsLayout(state.presets!);
        }
        context.read<PresetsBloc>().add(LoadPresetsEvent());
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
      buildWhen: (previous, current) {
        return current.status == PresetsOverviewStatus.loaded ||
            current.status == PresetsOverviewStatus.loading;
      },
    );
  }
}

class PresetsLayout extends StatelessWidget {
  final ValueListenable<Box<Preset>> presetListenable;

  const PresetsLayout(this.presetListenable, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text("Presets"),
        ),
      ),
      body: ValueListenableBuilder<Box<Preset>>(
        valueListenable: presetListenable,
        builder: (context, value, child) {
          final presets = value.values.toList();
          return ListView.builder(
            itemBuilder: (context, index) {
              Preset preset = presets[index];
              return ListCard(preset, () {
                navigateToEditPage(context, preset, (updatedPreset) {
                  sendUpdatePresetCommand(context, preset, updatedPreset);
                });
              }, () {
                sendDeletePresetCommand(context, preset);
              });
            },
            itemCount: presets.length,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          navigateToEditPage(context, null, (preset) {
            sendInsertPresetCommand(context, preset);
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // helper functions
  void navigateToEditPage(BuildContext context, Preset? preset,
      void Function(Preset preset) onResultReturned) async {
    final result = await Navigator.push<Preset>(
      context,
      MaterialPageRoute<Preset>(
        builder: (context) => EditPage(preset),
      ),
    );

    if (result != null) {
      onResultReturned(result);
    }
  }

  void sendInsertPresetCommand(BuildContext context, Preset preset) {
    context.read<PresetsBloc>().add(InsertPresetEvent(preset));
  }

  void sendDeletePresetCommand(BuildContext context, Preset preset) {
    context.read<PresetsBloc>().add(DeletePresetEvent(preset));
  }

  void sendUpdatePresetCommand(
      BuildContext context, Preset currentPreset, Preset updatedPreset) {
    context
        .read<PresetsBloc>()
        .add(UpdatePresetEvent(currentPreset, updatedPreset));
  }
}
