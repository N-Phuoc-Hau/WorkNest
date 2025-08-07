import 'package:flutter/material.dart';

import '../../shared/widgets/job_application_dialog.dart';

class ApplicationUtils {
  /// Show job application dialog
  static Future<void> showApplicationDialog({
    required BuildContext context,
    required int jobId,
    required String jobTitle,
    required String companyName,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return JobApplicationDialog(
          jobId: jobId,
          jobTitle: jobTitle,
          companyName: companyName,
        );
      },
    );
  }
}
