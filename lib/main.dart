import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const CancioneroApp());
}

class CancioneroApp extends StatelessWidget {
  const CancioneroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cancionero',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8E24AA),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const PortadaPantalla(),
    );
  }
}

// -------------------------------------------------------------
// MODELOS DE DATOS
// -------------------------------------------------------------
class Cancion {
  String id;
  String titulo;
  String artista;
  String letraConAcordes;

  Cancion({
    required this.id,
    required this.titulo,
    required this.artista,
    required this.letraConAcordes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'titulo': titulo,
        'artista': artista,
        'letraConAcordes': letraConAcordes,
      };

  factory Cancion.fromJson(Map<String, dynamic> json) => Cancion(
        id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        titulo: json['titulo'] ?? '',
        artista: json['artista'] ?? '',
        letraConAcordes: json['letraConAcordes'] ?? '',
      );
}

class Repertorio {
  String id;
  String nombre;
  bool esPrivada;
  String? pinCompartido;
  bool esUnido;
  List<Cancion> canciones;

  Repertorio({
    required this.id,
    required this.nombre,
    this.esPrivada = false,
    this.pinCompartido,
    this.esUnido = false,
    List<Cancion>? canciones,
  }) : canciones = canciones ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'esPrivada': esPrivada,
        'pinCompartido': pinCompartido,
        'esUnido': esUnido,
        'canciones': canciones.map((c) => c.toJson()).toList(),
      };

  factory Repertorio.fromJson(Map<String, dynamic> json) => Repertorio(
        id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        nombre: json['nombre'] ?? '',
        esPrivada: json['esPrivada'] ?? false,
        pinCompartido: json['pinCompartido'],
        esUnido: json['esUnido'] ?? false,
        canciones: json['canciones'] != null
            ? (json['canciones'] as List)
                .map((i) => Cancion.fromJson(i))
                .toList()
            : [],
      );
}

// -------------------------------------------------------------
// PANTALLA 1: PORTADA PRINCIPAL
// -------------------------------------------------------------
class PortadaPantalla extends StatefulWidget {
  const PortadaPantalla({super.key});

  @override
  State<PortadaPantalla> createState() => _PortadaPantallaState();
}

class _PortadaPantallaState extends State<PortadaPantalla> {
  List<Repertorio> misRepertorios = [];
  List<Repertorio> repertoriosUnidos = [];
  final Set<String> _repertoriosDesbloqueados = {};

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    final String? datosMis = prefs.getString('mis_repertorios_creados');
    final String? datosUnidos = prefs.getString('repertorios_unidos');

    setState(() {
      if (datosMis != null) {
        final List<dynamic> lista = jsonDecode(datosMis);
        misRepertorios = lista.map((i) => Repertorio.fromJson(i)).toList();
      }
      if (datosUnidos != null) {
        final List<dynamic> lista = jsonDecode(datosUnidos);
        repertoriosUnidos = lista.map((i) => Repertorio.fromJson(i)).toList();
      }
    });
  }

  Future<void> _guardarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'mis_repertorios_creados',
      jsonEncode(misRepertorios.map((r) => r.toJson()).toList()),
    );
    await prefs.setString(
      'repertorios_unidos',
      jsonEncode(repertoriosUnidos.map((r) => r.toJson()).toList()),
    );
  }

  void _crearRepertorioModal() {
    final nombreCtrl = TextEditingController();
    final pinCtrl = TextEditingController();
    bool esPrivada = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E2C),
            title: const Text('Crear Mi Repertorio',
                style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Repertorio',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white38)),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Proteger con PIN',
                      style: TextStyle(color: Colors.white)),
                  subtitle: Text(
                      esPrivada ? 'Carpeta protegida' : 'Carpeta normal',
                      style: const TextStyle(color: Colors.white60)),
                  value: esPrivada,
                  activeColor: Colors.purpleAccent,
                  onChanged: (val) => setModalState(() => esPrivada = val),
                ),
                if (esPrivada)
                  TextField(
                    controller: pinCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'PIN de 4 dígitos',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white38)),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child:
                    const Text('Cancelar', style: TextStyle(color: Colors.white60)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purpleAccent,
                    foregroundColor: Colors.white),
                onPressed: () {
                  if (nombreCtrl.text.isNotEmpty) {
                    final nuevo = Repertorio(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      nombre: nombreCtrl.text,
                      esPrivada: esPrivada,
                      pinCompartido:
                          esPrivada && pinCtrl.text.isNotEmpty ? pinCtrl.text : null,
                      esUnido: false,
                    );
                    setState(() {
                      misRepertorios.add(nuevo);
                      _repertoriosDesbloqueados.add(nuevo.id);
                    });
                    _guardarDatos();
                    Navigator.pop(context);
                    _irAPantallaRepertorios(esUnidos: false);
                  }
                },
                child: const Text('Crear y Abrir'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _unirseConPinModal() {
    final pinCtrl = TextEditingController();
    final nombreCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text('Ingresar con PIN',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingresa el nombre y PIN del repertorio:',
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            TextField(
              controller: nombreCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Nombre del Repertorio',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white38)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pinCtrl,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
              decoration: const InputDecoration(
                hintText: '****',
                hintStyle: TextStyle(color: Colors.white24),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white38)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancelar', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
            onPressed: () {
              final pinIngresado = pinCtrl.text.trim();
              final nombreIngresado = nombreCtrl.text.trim();
              if (pinIngresado.isNotEmpty && nombreIngresado.isNotEmpty) {
                Repertorio? repertorioEncontrado;
                for (var r in repertoriosUnidos) {
                  if (r.pinCompartido == pinIngresado) {
                    repertorioEncontrado = r;
                    break;
                  }
                }
                if (repertorioEncontrado != null) {
                  _repertoriosDesbloqueados.add(repertorioEncontrado.id);
                  Navigator.pop(context);
                  _irAPantallaRepertorios(esUnidos: true);
                } else {
                  final unido = Repertorio(
                    id: 'unido_$pinIngresado',
                    nombre: nombreIngresado,
                    esPrivada: true,
                    pinCompartido: pinIngresado,
                    esUnido: true,
                  );
                  setState(() {
                    repertoriosUnidos.add(unido);
                    _repertoriosDesbloqueados.add(unido.id);
                  });
                  _guardarDatos();
                  Navigator.pop(context);
                  _irAPantallaRepertorios(esUnidos: true);
                }
              }
            },
            child: const Text('Unirse'),
          ),
        ],
      ),
    );
  }

  void _irAPantallaRepertorios({required bool esUnidos}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListaRepertoriosPantalla(
          tituloPantalla: esUnidos ? 'Repertorios Unidos' : 'Mis Repertorios',
          lista: esUnidos ? repertoriosUnidos : misRepertorios,
          esModoUnidos: esUnidos,
          repertoriosDesbloqueados: _repertoriosDesbloqueados,
          onGuardarCambios: () => _guardarDatos(),
        ),
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2A0845), Color(0xFF6441A5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.purpleAccent.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5)
                    ],
                  ),
                  child: const Icon(Icons.music_note_rounded,
                      size: 80, color: Colors.cyanAccent),
                ),
                const SizedBox(height: 24),
                const Text(
                  'CANCIONERO',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Gestor Pro de Acordes y Repertorios',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 15, letterSpacing: 0.5),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2A0845),
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _crearRepertorioModal,
                    icon: const Icon(Icons.add_circle_outline, size: 24),
                    label: const Text('Crear Mi Repertorio',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.cyanAccent, width: 2),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _unirseConPinModal,
                    icon: const Icon(Icons.lock_open_rounded,
                        size: 24, color: Colors.cyanAccent),
                    label: const Text('Ingresar con PIN',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold)),
                  ),
                ),
                if (misRepertorios.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB300),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => _irAPantallaRepertorios(esUnidos: false),
                      icon: const Icon(Icons.folder_special, size: 24),
                      label: Text(
                        'Mis Repertorios (${misRepertorios.length})',
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
                if (repertoriosUnidos.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E676),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => _irAPantallaRepertorios(esUnidos: true),
                      icon: const Icon(Icons.group_work, size: 24),
                      label: Text(
                        'Repertorios Unidos (${repertoriosUnidos.length})',
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// PANTALLA 2: LISTA DE REPERTORIOS
// -------------------------------------------------------------
class ListaRepertoriosPantalla extends StatefulWidget {
  final String tituloPantalla;
  final List<Repertorio> lista;
  final bool esModoUnidos;
  final Set<String> repertoriosDesbloqueados;
  final VoidCallback onGuardarCambios;

  const ListaRepertoriosPantalla({
    super.key,
    required this.tituloPantalla,
    required this.lista,
    required this.esModoUnidos,
    required this.repertoriosDesbloqueados,
    required this.onGuardarCambios,
  });

  @override
  State<ListaRepertoriosPantalla> createState() =>
      _ListaRepertoriosPantallaState();
}

class _ListaRepertoriosPantallaState extends State<ListaRepertoriosPantalla> {
  void _verificarPinYAbrir(Repertorio rep) {
    // Si ya fue desbloqueado en esta sesión, abre directo sin pedir PIN de nuevo
    if (widget.repertoriosDesbloqueados.contains(rep.id)) {
      _abrirDetalleCarpeta(rep);
      return;
    }

    if (rep.esPrivada &&
        rep.pinCompartido != null &&
        rep.pinCompartido!.isNotEmpty) {
      final pinCtrl = TextEditingController();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          title: const Text('Acceso Protegido',
              style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: pinCtrl,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Ingrese PIN para acceder',
              labelStyle: TextStyle(color: Colors.white70),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white38)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('Cancelar', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  foregroundColor: Colors.white),
              onPressed: () {
                if (pinCtrl.text.trim() == rep.pinCompartido) {
                  widget.repertoriosDesbloqueados.add(rep.id);
                  Navigator.pop(context);
                  _abrirDetalleCarpeta(rep);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('PIN incorrecto'),
                        backgroundColor: Colors.redAccent),
                  );
                }
              },
              child: const Text('Ingresar'),
            ),
          ],
        ),
      );
    } else {
      widget.repertoriosDesbloqueados.add(rep.id);
      _abrirDetalleCarpeta(rep);
    }
  }

  void _abrirDetalleCarpeta(Repertorio rep) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetalleRepertorioPantalla(
          repertorio: rep,
          onGuardar: () {
            widget.onGuardarCambios();
            setState(() {});
          },
        ),
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tituloPantalla,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E1E2C),
      ),
      body: widget.lista.isEmpty
          ? Center(
              child: Text(
                widget.esModoUnidos
                    ? 'No hay repertorios unidos.'
                    : 'No has creado repertorios.',
                style: const TextStyle(fontSize: 16, color: Colors.white60),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: widget.lista.length,
              itemBuilder: (context, index) {
                final rep = widget.lista[index];
                return Card(
                  color: const Color(0xFF1E1E2C),
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: rep.esPrivada
                          ? Colors.amber.withOpacity(0.2)
                          : Colors.purple.withOpacity(0.2),
                      child: Icon(
                        rep.esPrivada ? Icons.lock : Icons.folder,
                        color: rep.esPrivada
                            ? Colors.amberAccent
                            : Colors.purpleAccent,
                      ),
                    ),
                    title: Text(
                      rep.nombre,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white),
                    ),
                    subtitle: Text(
                      rep.esPrivada
                          ? 'Protegido con PIN • ${rep.canciones.length} canciones'
                          : 'Normal • ${rep.canciones.length} canciones',
                      style: const TextStyle(color: Colors.white60),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.redAccent),
                      onPressed: () {
                        setState(() {
                          widget.repertoriosDesbloqueados.remove(rep.id);
                          widget.lista.removeAt(index);
                        });
                        widget.onGuardarCambios();
                      },
                    ),
                    onTap: () => _verificarPinYAbrir(rep),
                  ),
                );
              },
            ),
    );
  }
}

// -------------------------------------------------------------
// PANTALLA 3: DETALLE DE REPERTORIO Y CANCIONES
// -------------------------------------------------------------
class DetalleRepertorioPantalla extends StatefulWidget {
  final Repertorio repertorio;
  final VoidCallback onGuardar;

  const DetalleRepertorioPantalla({
    super.key,
    required this.repertorio,
    required this.onGuardar,
  });

  @override
  State<DetalleRepertorioPantalla> createState() =>
      _DetalleRepertorioPantallaState();
}

class _DetalleRepertorioPantallaState extends State<DetalleRepertorioPantalla> {
  String _filtroBusqueda = '';

  void _modalAgregarEditarCancion({Cancion? cancionExistente, int? index}) {
    final tituloCtrl = TextEditingController(text: cancionExistente?.titulo ?? '');
    final artistaCtrl =
        TextEditingController(text: cancionExistente?.artista ?? '');
    final letraCtrl = TextEditingController(
      text: cancionExistente?.letraConAcordes ??
          'C           G\nDios está aquí\nAm          F\nTan cierto como el aire',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: Text(
            cancionExistente == null ? 'Agregar Canción' : 'Editar Canción',
            style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tituloCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Título',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white38)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: artistaCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Artista / Autor',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white38)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: letraCtrl,
                maxLines: 6,
                style: const TextStyle(
                    color: Colors.white, fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  labelText: 'Letra con Acordes arriba',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white38)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancelar', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purpleAccent,
                foregroundColor: Colors.white),
            onPressed: () {
              if (tituloCtrl.text.isNotEmpty) {
                setState(() {
                  if (cancionExistente == null) {
                    widget.repertorio.canciones.add(
                      Cancion(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        titulo: tituloCtrl.text,
                        artista: artistaCtrl.text,
                        letraConAcordes: letraCtrl.text,
                      ),
                    );
                  } else if (index != null) {
                    widget.repertorio.canciones[index] = Cancion(
                      id: cancionExistente.id,
                      titulo: tituloCtrl.text,
                      artista: artistaCtrl.text,
                      letraConAcordes: letraCtrl.text,
                    );
                  }
                });
                widget.onGuardar();
                Navigator.pop(context);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _duplicarCancion(int index) {
    final original = widget.repertorio.canciones[index];
    final copia = Cancion(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      titulo: '${original.titulo} (Copia)',
      artista: original.artista,
      letraConAcordes: original.letraConAcordes,
    );
    setState(() {
      widget.repertorio.canciones.add(copia);
    });
    widget.onGuardar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Canción "${original.titulo}" duplicada')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cancionesFiltradas = widget.repertorio.canciones.where((c) {
      final query = _filtroBusqueda.toLowerCase();
      return c.titulo.toLowerCase().contains(query) ||
          c.artista.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.repertorio.nombre,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E1E2C),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (val) => setState(() => _filtroBusqueda = val),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar canción o artista...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon:
                    const Icon(Icons.search, color: Colors.purpleAccent),
                filled: true,
                fillColor: const Color(0xFF1E1E2C),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: cancionesFiltradas.isEmpty
                ? const Center(
                    child: Text('No se encontraron canciones.',
                        style: TextStyle(color: Colors.white60)),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    itemCount: cancionesFiltradas.length,
                    itemBuilder: (context, index) {
                      final cancion = cancionesFiltradas[index];
                      return Card(
                        color: const Color(0xFF1E1E2C),
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          leading: const CircleAvatar(
                            backgroundColor: Colors.purpleAccent,
                            child: Icon(Icons.music_note, color: Colors.black),
                          ),
                          title: Text(cancion.titulo,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 16)),
                          subtitle: Text(
                            cancion.artista.isNotEmpty
                                ? cancion.artista
                                : 'Autor desconocido',
                            style: const TextStyle(color: Colors.white60),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.copy,
                                    color: Colors.cyanAccent, size: 20),
                                onPressed: () => _duplicarCancion(widget
                                    .repertorio.canciones
                                    .indexOf(cancion)),
                                tooltip: 'Duplicar',
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined,
                                    color: Colors.orangeAccent, size: 20),
                                onPressed: () => _modalAgregarEditarCancion(
                                  cancionExistente: cancion,
                                  index: widget.repertorio.canciones
                                      .indexOf(cancion),
                                ),
                                tooltip: 'Editar',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.redAccent, size: 20),
                                onPressed: () {
                                  setState(() {
                                    widget.repertorio.canciones.remove(cancion);
                                  });
                                  widget.onGuardar();
                                },
                                tooltip: 'Eliminar',
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    VisorCancionPantalla(cancion: cancion),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purpleAccent,
        foregroundColor: Colors.white,
        onPressed: () => _modalAgregarEditarCancion(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// -------------------------------------------------------------
// PANTALLA 4: VISOR DE CANCIÓN
// -------------------------------------------------------------
class VisorCancionPantalla extends StatefulWidget {
  final Cancion cancion;
  const VisorCancionPantalla({super.key, required this.cancion});

  @override
  State<VisorCancionPantalla> createState() => _VisorCancionPantallaState();
}

class _VisorCancionPantallaState extends State<VisorCancionPantalla> {
  int _semitonos = 0;
  double _fontSize = 18.0;
  bool _autoScrollActivo = false;
  double _velocidadScroll = 1.0;
  Timer? _timerScroll;
  final ScrollController _scrollController = ScrollController();
  final List<String> _notasNivel = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B'
  ];

  void _iniciarDetenerAutoScroll() {
    setState(() {
      _autoScrollActivo = !_autoScrollActivo;
    });
    _timerScroll?.cancel();
    if (_autoScrollActivo) {
      _reprogramarTimerScroll();
    }
  }

  void _reprogramarTimerScroll() {
    _timerScroll?.cancel();
    int ms = (100 / _velocidadScroll).round();
    _timerScroll = Timer.periodic(Duration(milliseconds: ms), (timer) {
      if (_scrollController.hasClients) {
        double maxScroll = _scrollController.position.maxScrollExtent;
        double currentScroll = _scrollController.offset;
        if (currentScroll < maxScroll) {
          _scrollController.animateTo(
            currentScroll + 1.5,
            duration: Duration(milliseconds: ms),
            curve: Curves.linear,
          );
        } else {
          _timerScroll?.cancel();
          setState(() => _autoScrollActivo = false);
        }
      }
    });
  }

  void _cambiarVelocidad(double nuevaVelocidad) {
    setState(() {
      _velocidadScroll = nuevaVelocidad;
    });
    if (_autoScrollActivo) {
      _reprogramarTimerScroll();
    }
  }

  String _transponerAcordes(String texto, int pasos) {
    if (pasos == 0) return texto;
    final RegExp regex =
        RegExp(r'\b[A-G](?:#|b)?(?:m|maj|min|dim|aug|7|9|11|sus[24])*\b');
    return texto.replaceAllMapped(regex, (match) {
      String acorde = match.group(0)!;
      return _transponerUnAcorde(acorde, pasos);
    });
  }

  String _transponerUnAcorde(String acorde, int pasos) {
    String raiz = acorde;
    String sufijo = '';
    if (acorde.length > 1 && (acorde[1] == '#' || acorde[1] == 'b')) {
      raiz = acorde.substring(0, 2);
      sufijo = acorde.substring(2);
    } else {
      raiz = acorde.substring(0, 1);
      sufijo = acorde.substring(1);
    }
    if (raiz == 'Db') raiz = 'C#';
    if (raiz == 'Eb') raiz = 'D#';
    if (raiz == 'Gb') raiz = 'F#';
    if (raiz == 'Ab') raiz = 'G#';
    if (raiz == 'Bb') raiz = 'A#';
    int index = _notasNivel.indexOf(raiz);
    if (index == -1) return acorde;
    int nuevoIndex = (index + pasos) % 12;
    if (nuevoIndex < 0) nuevoIndex += 12;
    return _notasNivel[nuevoIndex] + sufijo;
  }

  @override
  void dispose() {
    _timerScroll?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String letraTranspuesta =
        _transponerAcordes(widget.cancion.letraConAcordes, _semitonos);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cancion.titulo,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E1E2C),
        actions: [
          DropdownButton<double>(
            value: _velocidadScroll,
            dropdownColor: const Color(0xFF1E1E2C),
            underline: const SizedBox(),
            icon: const Icon(Icons.speed, color: Colors.purpleAccent),
            items: const [
              DropdownMenuItem(
                  value: 0.5,
                  child: Text('0.5x', style: TextStyle(color: Colors.white))),
              DropdownMenuItem(
                  value: 1.0,
                  child: Text('1.0x', style: TextStyle(color: Colors.white))),
              DropdownMenuItem(
                  value: 1.5,
                  child: Text('1.5x', style: TextStyle(color: Colors.white))),
              DropdownMenuItem(
                  value: 2.0,
                  child: Text('2.0x', style: TextStyle(color: Colors.white))),
            ],
            onChanged: (val) {
              if (val != null) _cambiarVelocidad(val);
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(_autoScrollActivo
                ? Icons.pause_circle_filled
                : Icons.play_circle_fill),
            color: _autoScrollActivo ? Colors.greenAccent : Colors.purpleAccent,
            iconSize: 32,
            onPressed: _iniciarDetenerAutoScroll,
            tooltip: 'Autodesplazamiento',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF1E1E2C),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('Tono: ',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white70)),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: Colors.purpleAccent),
                      onPressed: () => setState(() => _semitonos--),
                    ),
                    Text(
                      '${_semitonos > 0 ? "+$_semitonos" : _semitonos}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline,
                          color: Colors.purpleAccent),
                      onPressed: () => setState(() => _semitonos++),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.text_fields,
                        size: 20, color: Colors.white70),
                    IconButton(
                      icon: const Icon(Icons.text_decrease,
                          color: Colors.purpleAccent),
                      onPressed: () {
                        if (_fontSize > 12) setState(() => _fontSize -= 2);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.text_increase,
                          color: Colors.purpleAccent),
                      onPressed: () {
                        if (_fontSize < 36) setState(() => _fontSize += 2);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              child: SelectableText(
                letraTranspuesta,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: _fontSize,
                  height: 1.6,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
