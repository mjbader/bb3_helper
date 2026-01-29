import 'dart:convert';
import 'dart:io';

import 'package:bb3_helper/auth.dart';
import 'package:bb3_helper/models/league.dart';
import 'package:bb3_helper/services/admin_website_service.dart';
import 'package:bloodbowl3_dart/bloodbowl3.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';

class CreateCompetition extends StatefulWidget {
  final League league;

  const CreateCompetition({super.key, required this.league});

  @override
  State<StatefulWidget> createState() => _CreateCompetitionState();
}

class _CreateCompetitionState extends State<CreateCompetition> {
  // Suffix + Team Ids
  late FluentThemeData _theme;
  final _groups = <String, List<String>>{};
  var _prefix = '';
  var _loadingProgress = 0.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _theme = FluentTheme.of(context);
  }

  Future<void> _pickCsv() async {
    _groups.clear();
    final file = await FilePicker.platform.pickFiles();

    if (file != null && file.paths.first != null) {
      final input = File(file.paths.first!).openRead();
      final fields = await input
          .transform(utf8.decoder)
          .transform(CsvToListConverter())
          .toList();
      for (final field in fields) {
        _groups[field[0]] = field
            .sublist(1)
            .map((element) => element.toString())
            .toList();
      }
    }
    setState(() {});
  }

  Future<void> _createCompetitions() async {
    // Login to BB3 Game Server and Create AI Competitions
    var client = BB3_Client();
    await client.connect();

    await client.send(
      RequestLogin(authService: 'steam', authToken: getAuthCode()),
    );

    List<String> compIds = [];

    for (final groupEntry in _groups.entries) {
      RequestCreateCompetition requestCreateCompetition =
          RequestCreateCompetition(
            name: '$_prefix${groupEntry.key}',
            format: CompetitionFormat.roundRobin,
            leagueId: widget.league.id,
            participantsNumberMax: groupEntry.value.length,
            admissionMode: CompetitionAdmissionMode.offeredTickets,
            logoId: "88A0368A913B55E6A5807451A9F171ED",
          );
      ResponseCreateCompetition responseCreateCompetition = await client.send(
        requestCreateCompetition,
      );
      var settingId = responseCreateCompetition.competition!.settingId;
      await client.send(
        RequestSetAllowParticipantMatchValidation(
          settingId: settingId,
          allowParticipantMatchValidation: true,
        ),
      );
      await client.send(
        RequestSetAllowExperiencedTeams(
          settingId: settingId,
          allowExperiencedTeams: true,
        ),
      );
      await client.send(
        RequestSetAutomaticMatchValidation(
          settingId: settingId,
          automaticMatchValidation: false,
        ),
      );
      await client.send(
        RequestSetContestFormat(
          settingId: settingId,
          contestFormat: ContestFormat.singleMatch,
        ),
      );
      for (int i = 0; i < groupEntry.value.length; i++) {
        await client.send(
          RequestAddAIToCompetition(
            compId: responseCreateCompetition.competition!.id,
          ),
        );
      }
      compIds.add(responseCreateCompetition.competition!.id);
    }

    // Now Enter the competitions and swap the team ids with the AIs.
    await AdminWebsiteService.instance.reload();

    for (var compId in compIds.indexed) {
      await AdminWebsiteService.instance.selectCompetition(compId.$2);

      final aiTeams = AdminWebsiteService.instance.compTeams;

      for (var aiTeam in aiTeams.indexed) {
        await AdminWebsiteService.instance.replaceTeam(
          replacingTeamId: _groups.values.toList()[compId.$1][aiTeam.$1],
          replacedTeamId: aiTeam.$2.id,
        );
      }
    }
  }

  Widget _buildGroupsPreview() {
    return Container(
      decoration: BoxDecoration(border: Border.all(width: 1.0,)),
      height: 300,
      width: 500,
      child: ListView.builder(
        itemCount: _groups.length,
        itemBuilder: (context, index) {
          final divisions = _groups.entries.map((groupEntry) {
            return Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  '$_prefix${groupEntry.key}',
                  style: _theme.typography.title,
                ),
                for (var teamId in groupEntry.value) Text(teamId),
              ],
            );
          }).toList();

          return divisions[index];
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: Text('Create Competitions For ${widget.league.name}'),
      ),
      content: Column(
        crossAxisAlignment: .start,
        spacing: 16,
        children: [
          SizedBox(
            width: 400,
            child: InfoLabel(
              label: 'Enter Competition Prefix',
              child: TextBox(
                placeholder: "Prefix",
                onChanged: (value) {
                  setState(() {
                    _prefix = value;
                  });
                },
              ),
            ),
          ),
          Button(onPressed: _pickCsv, child: Text('CSV File Picker')),
          Button(
            onPressed: _groups.isNotEmpty ? _createCompetitions : null,
            child: Text('Submit'),
          ),
          if (_loadingProgress != 0.0) ProgressBar(value: _loadingProgress),
          if (_groups.isNotEmpty) _buildGroupsPreview(),
        ],
      ),
    );
  }
}
