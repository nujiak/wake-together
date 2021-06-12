import 'package:flutter/material.dart';

/// Shows an input dialog and returns a Future<String?> containing the
/// result of the input.
Future<String?> showInputDialog(
    {required BuildContext context,
    String? title,
    String? labelText,
    String? initialText,
    required String doneAction,
    String? cancelAction,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.sentences}) {
  return showDialog<String>(
      context: context,
      builder: (context) {
        // Key used for form validation.
        GlobalKey<FormState> _formFieldKey = GlobalKey<FormState>();

        // Controller for accessing text field contents.
        TextEditingController controller = TextEditingController();

        // FocusNode for controlling autofocus.
        FocusNode focusNode = FocusNode();

        // Make focusNode select all text in controller.
        focusNode.addListener(() {
          controller.selection =
              TextSelection(baseOffset: 0, extentOffset: controller.text.length);
        });

        // Function for validating text field and submitting.
        void onPressed() {
          if (_formFieldKey.currentState != null &&
              _formFieldKey.currentState!.validate()) {
            Navigator.pop(context, controller.text.trim());
          }
        }
        
        controller.text = initialText ?? "";
        return AlertDialog(
          titlePadding: EdgeInsets.only(left: 24, top: 16),
          contentPadding: EdgeInsets.only(left: 16, right: 16, top: 16),
          buttonPadding: EdgeInsets.all(0),
          actionsPadding: EdgeInsets.only(right: 16),
          title: title != null ? Text(title) : null,
          content: Form(
            key: _formFieldKey,
            child: TextFormField(
              focusNode: focusNode,
              controller: controller,
              validator: validator,
              autofocus: true,
              textCapitalization: textCapitalization,
              onFieldSubmitted: (_) => onPressed(),
              decoration: InputDecoration(
                isDense: true,
                labelText: labelText,
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            if (cancelAction != null)
              StyledButton(
                splash: false,
                onPressed: () => Navigator.pop(context),
                text: cancelAction,
                buttonType: ButtonType.text,
              ),
            StyledButton(
                splash: false,
                onPressed: onPressed,
                text: doneAction,
                buttonType: ButtonType.text)
          ],
        );
      });
}

enum ButtonType {
  elevated,
  outlined,
  text,
}

/// Styled button with semi-bold text to be used throughout the app.
class StyledButton extends StatelessWidget {
  const StyledButton({
    required this.text,
    required this.onPressed,
    this.buttonType = ButtonType.elevated,
    this.splash = true,
    this.style,
  });

  final String text;
  final void Function() onPressed;
  final ButtonType buttonType;
  final bool splash;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final Widget child =
        Text(text, style: TextStyle(fontWeight: FontWeight.w600));
    final ButtonStyle style;
    if (this.style != null) {
      style = this
          .style!
          .copyWith(splashFactory: splash ? null : NoSplash.splashFactory);
    } else {
      style = ButtonStyle(splashFactory: NoSplash.splashFactory);
    }

    switch (buttonType) {
      case ButtonType.elevated:
        return ElevatedButton(
          onPressed: onPressed,
          child: child,
          style: style,
        );
      case ButtonType.outlined:
        return OutlinedButton(
          onPressed: onPressed,
          child: child,
          style: style,
        );
      case ButtonType.text:
        return TextButton(
          onPressed: onPressed,
          child: child,
          style: style,
        );
    }
  }
}