import 'package:bb3_helper/models/league.dart';
import 'package:bb3_helper/services/admin_website_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';
class Competitions extends StatelessWidget {
  const Competitions({super.key, required this.league});

  final League league;


  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: AdminWebsiteService.instance,
        builder: (BuildContext context, Widget? child) {
          if (AdminWebsiteService.instance.leagueCompetitions.isEmpty) {
            return Center(
              child: Text('No competitions available'),
            );
          }
          
          return ScaffoldPage(
            header: PageHeader(
              title: Text(league.name),
              commandBar: CommandBar(
                mainAxisAlignment: .end,
                primaryItems: [
                CommandBarButton(
                  icon: WindowsIcon(WindowsIcons.document),
                  label: Text('CSV Comp Creation'),
                  onPressed: () {
                    if (context.mounted) {
                      context.push('/create_competitions', extra: league);
                    }
                  },
                ),
              ]),
              ),
            content: ListView.builder(
            itemCount: AdminWebsiteService.instance.leagueCompetitions.length,
            itemBuilder: (context, index) {
              final comp = AdminWebsiteService.instance.leagueCompetitions[index];
              return ListTile(
                  title: Text(comp.name),
                  onPressed: () async {
                    await AdminWebsiteService.instance.selectCompetition(comp.id);
                    if (context.mounted) {
                      context.go('/competition', extra: comp);
                    }
                  },
                );
            },
          ),
          );
        },
      );
  }
}