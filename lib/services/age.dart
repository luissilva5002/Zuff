import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zuff/pages/profile/profile.dart';
import 'package:zuff/home.dart';

class Age{
int calculateAge(String birthDateString) {
  final birthDate = DateFormat('yyyy-MM-dd').parse(birthDateString);
  final currentDate = DateTime.now();

  int age = currentDate.year - birthDate.year;
  if (currentDate.month < birthDate.month ||
      (currentDate.month == birthDate.month && currentDate.day < birthDate.day)) {
    age--;
  }

  return age;
}
}
