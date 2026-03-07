int crossAxisCountFor(double width) {
  if (width >= 1000) return 3;
  if (width >= 700) return 2;
  return 1;
}
