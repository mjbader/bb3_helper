import 'package:bb3_helper/models/competition.dart';
import 'package:bb3_helper/models/team.dart';
import 'package:bb3_helper/services/admin_website_service.dart';
import 'package:fluent_ui/fluent_ui.dart';

class CompetitionScreen extends StatefulWidget {
  const CompetitionScreen({super.key, required this.competition});

  final Competition competition;

  @override
  State<StatefulWidget> createState() => _CompetitionScreenState();
}

class _CompetitionScreenState extends State<CompetitionScreen> {
  late FluentThemeData _theme;

  final TextEditingController _replacingTeamTextController =
      TextEditingController();
  final TextEditingController _replacedTeamTextController =
      TextEditingController();
  Team? _replacingTeam;
  Team? _replacedTeam;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _theme = FluentTheme.of(context);
  }

  Future<void> _replaceTeams() async {
    if (_replacedTeam == null || _replacingTeam == null) {
      return;
    }

    var success = await AdminWebsiteService.instance.replaceTeam(
      replacingTeamId: _replacingTeam!.id,
      replacedTeamId: _replacedTeam!.id,
    );

    if (context.mounted) {
      if (!success) {
        await displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Replace Team Failed'),
              action: IconButton(
                icon: const WindowsIcon(WindowsIcons.clear),
                onPressed: close,
              ),
              severity: InfoBarSeverity.error,
            );
          },
        );
      } else {
        await displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Replace Team Success'),
              action: IconButton(
                icon: const WindowsIcon(WindowsIcons.clear),
                onPressed: close,
              ),
              severity: InfoBarSeverity.success,
            );
          },
        );
      }
    }

    _replacedTeamTextController.clear();
    _replacingTeamTextController.clear();
  }

  Widget _buildReplaceTeamTile() {
    return Column(
      spacing: 16,
      children: [
        Text("Replace Team", style: _theme.typography.title),
        AutoSuggestBox<Team>(
          placeholder: "Replaced Team",
          controller: _replacedTeamTextController,
          items: [
            for (final team in AdminWebsiteService.instance.compTeams)
              AutoSuggestBoxItem<Team>(value: team, label: team.name),
          ],
          onChanged: (text, reason) {
            setState(() {
              if (reason == .cleared) {
                _replacedTeam = null;
              }
            });
          },
          onSelected: (box) {
            setState(() {
              _replacedTeam = box.value;
            });
          },
        ),
        AutoSuggestBox<Team>(
          placeholder: "Replacing Team",
          controller: _replacingTeamTextController,
          items: [
            for (final team in AdminWebsiteService.instance.replacingTeams)
              AutoSuggestBoxItem<Team>(value: team, label: team.name),
          ],
          onChanged: (text, reason) {
            setState(() {
              if (reason == .cleared) {
                _replacingTeam = null;
              }
            });
          },
          onSelected: (box) {
            setState(() {
              _replacingTeam = box.value;
            });
          },
        ),
        Button(
          onPressed: _replacedTeam == null || _replacingTeam == null
              ? null
              : _replaceTeams,
          child: Text('Submit'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.withPadding(
      header: PageHeader(title: Text(widget.competition.name)),
      content: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = constraints.maxWidth > 600;
          final crossAxisCount = isLargeScreen ? 3 : 2;
          final itemCount = 1;

          return ListenableBuilder(
            listenable: AdminWebsiteService.instance,
            builder: (BuildContext context, Widget? child) {
              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  return _buildReplaceTeamTile();
                },
              );
            },
          );
        },
      ),
    );
  }
}
