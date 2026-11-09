//branch vise data representation model
//describes about branches

class Branch {
  const Branch({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.isHeadOffice = false,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final bool isHeadOffice;
}

class Branches {
  Branches._();

  static const all = <Branch>[
    Branch(id: 'colombo', name: 'Colombo HQ', latitude: 6.9151615962427115, longitude: 79.85987453781843, isHeadOffice: true),
    Branch(id: 'negombo', name: 'Negombo', latitude: 7.212765898063393, longitude: 79.84110667759099),
    Branch(id: 'gampaha', name: 'Gampaha', latitude: 7.091876091597664 , longitude: 79.99524788309205),
    Branch(id: 'kalutara', name: 'Kalutara', latitude: 6.578719120247456, longitude: 79.9623272005023),
    Branch(id: 'moratuwa', name: 'Moratuwa', latitude: 6.787722889872609, longitude: 79.88605734801502),
    Branch(id: 'wellawatta', name: 'Wellawatta', latitude: 6.867275756235836,  longitude: 79.86068724515457),
    Branch(id: 'mathugama', name: 'Mathugama', latitude: 6.521653875226601, longitude: 80.11450027683964),
    Branch(id: 'kotahena', name: 'Kotahena', latitude: 6.948573084805999,  longitude: 79.86238221700089),
  ];

  static Branch? byId(String? id) {
    for (final branch in all) {
      if (branch.id == id) return branch;
    }
    return null;
  }
}