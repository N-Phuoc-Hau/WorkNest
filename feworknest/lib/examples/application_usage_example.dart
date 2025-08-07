// Ví dụ sử dụng trong JobCard hoặc JobDetailScreen

import 'package:flutter/material.dart';

import '../utils/application_utils.dart';

class ExampleUsage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // Sử dụng để ứng tuyển job
        ApplicationUtils.showApplicationDialog(
          context: context,
          jobId: 123, // ID của job
          jobTitle: 'Senior Flutter Developer',
          companyName: 'ABC Company',
        );
      },
      child: Text('Ứng tuyển'),
    );
  }
}

/*
CÁCH SỬ DỤNG TRỰC TIẾP VỚI PROVIDER:

// 1. Import
import '../core/providers/application_provider.dart';

// 2. Trong Widget
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        final success = await ref.read(applicationProvider.notifier).submitApplication(
          jobId: 123,
          coverLetter: 'My cover letter...',
          cvFile: myPdfFile, // File object (mobile/desktop)
          // hoặc
          cvXFile: myXFile, // XFile object (web)
        );
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ứng tuyển thành công!')),
          );
        }
      },
      child: Text('Ứng tuyển'),
    );
  }
}
*/
