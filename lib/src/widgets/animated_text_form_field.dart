import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widget_helper.dart';

enum TextFieldInertiaDirection {
  left,
  right,
}

Interval _getInternalInterval(
  double start,
  double end,
  double externalStart,
  double externalEnd, [
  Curve curve = Curves.linear,
]) {
  return Interval(
    start + (end - start) * externalStart,
    start + (end - start) * externalEnd,
    curve: curve,
  );
}

class AnimatedTextFormField extends StatefulWidget {
  AnimatedTextFormField({
    Key key,
    this.interval = const Interval(0.0, 1.0),
    @required this.animatedWidth,
    this.loadingController,
    this.inertiaController,
    this.inertiaDirection,
    this.enabled = true,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.controller,
    this.focusNode,
    this.validator,
    this.onFieldSubmitted,
    this.onSaved,
  })  : assert((inertiaController == null && inertiaDirection == null) ||
            (inertiaController != null && inertiaDirection != null)),
        super(key: key);

  final Interval interval;
  final AnimationController loadingController;
  final AnimationController inertiaController;
  final double animatedWidth;
  final bool enabled;
  final String labelText;
  final Widget prefixIcon;
  final Widget suffixIcon;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final TextEditingController controller;
  final FocusNode focusNode;
  final FormFieldValidator<String> validator;
  final ValueChanged<String> onFieldSubmitted;
  final FormFieldSetter<String> onSaved;
  final TextFieldInertiaDirection inertiaDirection;

  @override
  _AnimatedTextFormFieldState createState() => _AnimatedTextFormFieldState();
}

class _AnimatedTextFormFieldState extends State<AnimatedTextFormField> {
  Animation<double> scaleAnimation;
  Animation<double> sizeAnimation;
  Animation<double> suffixIconOpacityAnimation;

  Animation<double> fieldTranslateAnimation;
  Animation<double> iconRotationAnimation;
  Animation<double> iconTranslateAnimation;

  @override
  void initState() {
    super.initState();

    widget.inertiaController?.addStatusListener(onAniStatusChanged);

    final interval = widget.interval;
    final inertiaDirection = widget.inertiaDirection;
    final loadingController = widget.loadingController;

    if (loadingController != null) {
      scaleAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: loadingController,
        curve: _getInternalInterval(
            0, .2, interval.begin, interval.end, Curves.easeOutBack),
      ));
      suffixIconOpacityAnimation =
          Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: loadingController,
        curve: _getInternalInterval(.65, 1.0, interval.begin, interval.end),
      ));
      sizeAnimation = Tween<double>(
        begin: 48.0,
        end: widget.animatedWidth,
      ).animate(CurvedAnimation(
        parent: loadingController,
        curve: _getInternalInterval(
            .2, 1.0, interval.begin, interval.end, Curves.linearToEaseOut),
        reverseCurve: Curves.easeInExpo,
      ));
    }

    final inertiaController = widget.inertiaController;

    if (inertiaController != null) {
      fieldTranslateAnimation = Tween<double>(
        begin: 0.0,
        end: inertiaDirection == TextFieldInertiaDirection.right ? 15.0 : -15.0,
      ).animate(CurvedAnimation(
        parent: inertiaController,
        curve: Interval(0, .5, curve: Curves.easeOut),
        reverseCurve: Curves.easeIn,
      ));
      iconRotationAnimation =
          Tween<double>(begin: 0.0, end: pi / 12).animate(CurvedAnimation(
        parent: inertiaController,
        curve: Interval(.5, 1.0, curve: Curves.easeOut),
        reverseCurve: Curves.easeIn,
      ));
      iconTranslateAnimation =
          Tween<double>(begin: 0.0, end: 8.0).animate(CurvedAnimation(
        parent: inertiaController,
        curve: Interval(.5, 1.0, curve: Curves.easeOut),
        reverseCurve: Curves.easeIn,
      ));
    }
  }

  @override
  dispose() {
    widget.inertiaController?.removeStatusListener(onAniStatusChanged);
    super.dispose();
  }

  void onAniStatusChanged(status) {
    if (status == AnimationStatus.completed) {
      widget.inertiaController?.reverse();
    }
  }

  Widget _buildInertiaAnimation(Widget child) {
    if (widget.inertiaController == null) {
      return child;
    }

    final inertiaDirection = widget.inertiaDirection;
    final sign = inertiaDirection == TextFieldInertiaDirection.right ? 1 : -1;

    return AnimatedBuilder(
      animation: iconTranslateAnimation,
      builder: (context, child) => Transform(
        transform: Matrix4.identity()
          ..translate(sign * iconTranslateAnimation.value),
        child: child,
      ),
      child: AnimatedBuilder(
        animation: iconRotationAnimation,
        builder: (context, child) => Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..rotateZ(sign * iconRotationAnimation.value),
          child: child,
        ),
        child: child,
      ),
    );
  }

  InputDecoration _getInputDecoration(ThemeData theme) {
    final bgColor = theme.primaryColor.withOpacity(.075);
    final primaryColorSwatch = getMaterialColor(theme.primaryColor);
    final errorColor = theme.accentColor.withOpacity(.2);
    final borderRadius = BorderRadius.circular(100);

    return InputDecoration(
      filled: true,
      fillColor: bgColor,
      contentPadding: EdgeInsets.symmetric(vertical: 4.0),
      labelText: widget.labelText,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.transparent),
        borderRadius: borderRadius,
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: primaryColorSwatch.shade700, width: 1.5),
        borderRadius: borderRadius,
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: errorColor),
        borderRadius: borderRadius,
      ),
      border: OutlineInputBorder(
        borderRadius: borderRadius,
      ),
      prefixIcon: _buildInertiaAnimation(widget.prefixIcon),
      suffixIcon: _buildInertiaAnimation(widget.loadingController != null
          ? FadeTransition(
              opacity: suffixIconOpacityAnimation,
              child: widget.suffixIcon,
            )
          : widget.suffixIcon),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget textField = TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      decoration: _getInputDecoration(theme),
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      obscureText: widget.obscureText,
      onFieldSubmitted: widget.onFieldSubmitted,
      onSaved: widget.onSaved,
      validator: widget.validator,
      enabled: widget.enabled,
      style: TextStyle(color: Colors.black.withOpacity(.65)),
    );

    if (widget.loadingController != null) {
      textField = AnimatedBuilder(
        animation: sizeAnimation,
        builder: (context, child) => Transform(
          transform: Matrix4.identity()
            ..scale(scaleAnimation.value, scaleAnimation.value),
          alignment: Alignment.center,
          child: Container(
            width: sizeAnimation.value,
            child: child,
          ),
        ),
        child: textField,
      );
    }

    if (widget.inertiaController != null) {
      textField = AnimatedBuilder(
        animation: fieldTranslateAnimation,
        builder: (context, child) => Transform(
          transform: Matrix4.identity()
            ..translate(fieldTranslateAnimation.value),
          child: child,
        ),
        child: textField,
      );
    }

    return textField;
  }
}

class AnimatedPasswordTextFormField extends StatefulWidget {
  AnimatedPasswordTextFormField({
    Key key,
    this.interval = const Interval(0.0, 1.0),
    @required this.animatedWidth,
    this.loadingController,
    this.inertiaController,
    this.inertiaDirection,
    this.enabled = true,
    this.labelText,
    this.keyboardType,
    this.textInputAction,
    this.controller,
    this.focusNode,
    this.validator,
    this.onFieldSubmitted,
    this.onSaved,
  })  : assert((inertiaController == null && inertiaDirection == null) ||
            (inertiaController != null && inertiaDirection != null)),
        super(key: key);

  final Interval interval;
  final AnimationController loadingController;
  final AnimationController inertiaController;
  final double animatedWidth;
  final bool enabled;
  final String labelText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final TextEditingController controller;
  final FocusNode focusNode;
  final FormFieldValidator<String> validator;
  final ValueChanged<String> onFieldSubmitted;
  final FormFieldSetter<String> onSaved;
  final TextFieldInertiaDirection inertiaDirection;

  @override
  _AnimatedPasswordTextFormFieldState createState() =>
      _AnimatedPasswordTextFormFieldState();
}

class _AnimatedPasswordTextFormFieldState
    extends State<AnimatedPasswordTextFormField> {
  var _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return AnimatedTextFormField(
      interval: widget.interval,
      loadingController: widget.loadingController,
      inertiaController: widget.inertiaController,
      animatedWidth: widget.animatedWidth,
      enabled: widget.enabled,
      labelText: widget.labelText,
      prefixIcon: Icon(FontAwesomeIcons.lock, size: 20),
      suffixIcon: GestureDetector(
        onTap: () => setState(() => _obscureText = !_obscureText),
        dragStartBehavior: DragStartBehavior.down,
        child: AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          firstCurve: Curves.easeInOutSine,
          secondCurve: Curves.easeInOutSine,
          alignment: Alignment.center,
          layoutBuilder: (Widget topChild, _, Widget bottomChild, __) {
            return Stack(
              alignment: Alignment.center,
              children: <Widget>[bottomChild, topChild],
            );
          },
          firstChild: Icon(
            Icons.visibility,
            size: 25.0,
            semanticLabel: 'show password',
          ),
          secondChild: Icon(
            Icons.visibility_off,
            size: 25.0,
            semanticLabel: 'hide password',
          ),
          crossFadeState: _obscureText
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
        ),
      ),
      obscureText: _obscureText,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      controller: widget.controller,
      focusNode: widget.focusNode,
      validator: widget.validator,
      onFieldSubmitted: widget.onFieldSubmitted,
      onSaved: widget.onSaved,
      inertiaDirection: widget.inertiaDirection,
    );
  }
}