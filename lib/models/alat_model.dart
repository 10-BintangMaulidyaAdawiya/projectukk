class AlatModel {
final String id;
final String namaAlat;
final int stok;
final String status;


AlatModel({
required this.id,
required this.namaAlat,
required this.stok,
required this.status,
});


factory AlatModel.fromMap(Map<String, dynamic> map) {
return AlatModel(
id: map['id'],
namaAlat: map['nama_alat'],
stok: map['stok'],
status: map['status'],
);
}
}