import 'package:bb3_helper/models/league.dart';
import 'package:bb3_helper/services/admin_website_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
class Competitions extends StatelessWidget {
  const Competitions({super.key, required this.league});

  final League league;

  Future<FilePickerResult?> _pickCsv() async {
    return await FilePicker.platform.pickFiles();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return ListenableBuilder(
        listenable: AdminWebsiteService.instance,
        builder: (BuildContext context, Widget? child) {
          if (AdminWebsiteService.instance.leagueCompetitions.isEmpty) {
            return Center(
              child: Text('No competitions available'),
            );
          }
          
          return ScaffoldPage(
            header: Row(
              mainAxisAlignment: .spaceBetween,
              crossAxisAlignment: .center,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Text(league.name, style: theme.typography.title,),
                ),
                Padding(
                  padding: EdgeInsets.only(right: 16, bottom: 10),
                  child: Button(
                  onPressed: () {
                    _pickCsv();
                  },
                  child: Icon(WindowsIcons.document),
                  ),
                )
              ],
            ),
            content: ListView.builder(
            itemCount: AdminWebsiteService.instance.leagueCompetitions.length,
            itemBuilder: (context, index) {
              final comp = AdminWebsiteService.instance.leagueCompetitions[index];
              return ListTile(
                  title: Text(comp.name),
                  onPressed: () async {
                    // TODO
                  },
                );
            },
          ),
          );
        },
      );
  }
}