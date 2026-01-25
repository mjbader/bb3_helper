import 'package:bb3_helper/services/admin_website_service.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';
class Leagues extends StatelessWidget {
  const Leagues({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: AdminWebsiteService.instance,
        builder: (BuildContext context, Widget? child) {
          if (AdminWebsiteService.instance.leagues.isEmpty) {
            return Center(
              child: Text('No leagues available'),
            );
          }
          
          return ListView.builder(
            itemCount: AdminWebsiteService.instance.leagues.length,
            itemBuilder: (context, index) {
              final league = AdminWebsiteService.instance.leagues[index];
              return ListTile(
                  title: Text(league.name),
                  // subtitle: Text('ID: ${league.id}'),
                  onPressed: () async {
                    await AdminWebsiteService.instance.selectLeague(league.id);

                    if (context.mounted) {
                      context.push('/league_competitions', extra: league);
                    }
                  },
                );
            },
          );
        },
      );
  }
}