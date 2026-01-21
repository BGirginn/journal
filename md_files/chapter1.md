# FAZ 1 - MVP (Minimum Viable Product)
**Süre:** 4-6 hafta  
**Hedef:** Çalışan, kullanılabilir, tek kullanıcılı journal motoru

---

## 🎯 FAZ 1 HEDEF VE KAPSAM

### Ana Hedef
Kullanıcı **offline** olarak:
- Journal oluşturabilir
- Sayfa ekleyebilir
- Text, Image, Handwriting block'ları ekleyebilir
- Sayfa çevirebilir
- Tüm veriler kalıcı olarak saklanır

### Kapsam Dışı (Faz 2+)
- ❌ Kullanıcı hesapları / login
- ❌ Cloud sync
- ❌ Tema sistemi (sadece 1 default tema)
- ❌ Audio block
- ❌ Grup journal
- ❌ Export (PDF/ZIP)
- ❌ Bildirimler

### Başarı Kriterleri
- [ ] Kullanıcı 5 dakikada ilk journal'ını oluşturup 1 sayfa ekleyebiliyor
- [ ] Uygulama kapatılıp açılınca tüm veriler korunuyor
- [ ] Sayfa çevirme 60 FPS'de çalışıyor
- [ ] Crash rate < 1%
- [ ] 3 beta kullanıcısı 1 hafta boyunca günlük kullanabiliyor

---

## 📋 SPRINT PLANI

### Sprint 1 (Hafta 1-2): Temel & Data Layer

#### Milestone 1.1: Proje Kurulumu
**Süre:** 1-2 gün

**Görevler:**
- [ ] Android Studio projesi oluştur
  - Min SDK: 24 (Android 7.0)
  - Target SDK: 34 (Android 14)
  - Dil: Kotlin
  - Build system: Gradle
- [ ] Dependencies ekle:
  ```gradle
  // Room Database
  implementation "androidx.room:room-runtime:2.6.1"
  kapt "androidx.room:room-compiler:2.6.1"
  implementation "androidx.room:room-ktx:2.6.1"
  
  // Coroutines
  implementation "org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3"
  
  // ViewModel & LiveData
  implementation "androidx.lifecycle:lifecycle-viewmodel-ktx:2.7.0"
  implementation "androidx.lifecycle:lifecycle-livedata-ktx:2.7.0"
  
  // Jetpack Compose (UI)
  implementation "androidx.compose.ui:ui:1.6.0"
  implementation "androidx.compose.material3:material3:1.2.0"
  implementation "androidx.navigation:navigation-compose:2.7.6"
  
  // Image loading
  implementation "io.coil-kt:coil-compose:2.5.0"
  ```
- [ ] Proje yapısı oluştur:
  ```
  app/
    └── src/main/java/com/yourapp/journal/
        ├── data/
        │   ├── model/        # Entity classes
        │   ├── dao/          # Room DAOs
        │   └── repository/   # Repository implementations
        ├── domain/
        │   └── usecase/      # Business logic
        ├── ui/
        │   ├── library/      # Journal list screen
        │   ├── journal/      # Journal view screen
        │   └── editor/       # Page editor screen
        └── util/             # Helpers
  ```

**Tamamlanma kriteri:** Proje çalışıyor, boş Activity görünüyor

---

#### Milestone 1.2: Data Model
**Süre:** 2-3 gün

**Görevler:**
- [ ] **BaseEntity interface** oluştur:
  ```kotlin
  interface BaseEntity {
      val id: String
      val version: Int
      val createdAt: Long
      val updatedAt: Long
      val deletedAt: Long?
  }
  ```

- [ ] **Journal entity** oluştur:
  ```kotlin
  @Entity(tableName = "journals")
  data class Journal(
      @PrimaryKey override val id: String = UUID.randomUUID().toString(),
      val title: String,
      val coverStyle: String = "default",
      override val version: Int = 1,
      override val createdAt: Long = System.currentTimeMillis(),
      override val updatedAt: Long = System.currentTimeMillis(),
      override val deletedAt: Long? = null
  ) : BaseEntity
  ```

- [ ] **Page entity** oluştur:
  ```kotlin
  @Entity(
      tableName = "pages",
      foreignKeys = [ForeignKey(
          entity = Journal::class,
          parentColumns = ["id"],
          childColumns = ["journalId"],
          onDelete = ForeignKey.CASCADE
      )],
      indices = [Index("journalId"), Index("pageIndex")]
  )
  data class Page(
      @PrimaryKey override val id: String = UUID.randomUUID().toString(),
      val journalId: String,
      val pageIndex: Int,
      val backgroundStyle: String = "plain_white",
      val thumbnail: String? = null,
      override val version: Int = 1,
      override val createdAt: Long = System.currentTimeMillis(),
      override val updatedAt: Long = System.currentTimeMillis(),
      override val deletedAt: Long? = null
  ) : BaseEntity
  ```

- [ ] **Block entity** oluştur:
  ```kotlin
  @Entity(
      tableName = "blocks",
      foreignKeys = [ForeignKey(
          entity = Page::class,
          parentColumns = ["id"],
          childColumns = ["pageId"],
          onDelete = ForeignKey.CASCADE
      )],
      indices = [Index("pageId")]
  )
  data class Block(
      @PrimaryKey override val id: String = UUID.randomUUID().toString(),
      val pageId: String,
      val type: BlockType,
      val x: Float,
      val y: Float,
      val width: Float,
      val height: Float,
      val rotation: Float = 0f,
      val zIndex: Int = 0,
      val state: BlockState = BlockState.NORMAL,
      val data: String, // JSON
      override val version: Int = 1,
      override val createdAt: Long = System.currentTimeMillis(),
      override val updatedAt: Long = System.currentTimeMillis(),
      override val deletedAt: Long? = null
  ) : BaseEntity
  
  enum class BlockType {
      TEXT, IMAGE, HANDWRITING
  }
  
  enum class BlockState {
      NORMAL, SELECTED, EDITING, LOCKED
  }
  ```

- [ ] **Block Data classes** oluştur:
  ```kotlin
  sealed class BlockData {
      data class Text(
          val content: String,
          val fontSize: Float = 16f,
          val color: String = "#000000",
          val fontFamily: String = "default"
      ) : BlockData()
      
      data class Image(
          val filePath: String,
          val originalWidth: Int,
          val originalHeight: Int
      ) : BlockData()
      
      data class Handwriting(
          val strokesJson: String // Serialized stroke data
      ) : BlockData()
  }
  
  // JSON serialization helpers
  fun BlockData.toJson(): String { /* Gson/Moshi */ }
  fun String.toBlockData(): BlockData? { /* parse */ }
  ```

**Tamamlanma kriteri:** Tüm entity'ler derlenebiliyor, tip güvenliği var

---

#### Milestone 1.3: Database Layer
**Süre:** 2 gün

**Görevler:**
- [ ] **JournalDao** oluştur:
  ```kotlin
  @Dao
  interface JournalDao {
      @Query("SELECT * FROM journals WHERE deletedAt IS NULL ORDER BY updatedAt DESC")
      fun getAllFlow(): Flow<List<Journal>>
      
      @Query("SELECT * FROM journals WHERE id = :id AND deletedAt IS NULL")
      suspend fun getById(id: String): Journal?
      
      @Insert(onConflict = OnConflictStrategy.REPLACE)
      suspend fun insert(journal: Journal)
      
      @Update
      suspend fun update(journal: Journal)
      
      @Query("UPDATE journals SET deletedAt = :timestamp WHERE id = :id")
      suspend fun softDelete(id: String, timestamp: Long = System.currentTimeMillis())
  }
  ```

- [ ] **PageDao** oluştur:
  ```kotlin
  @Dao
  interface PageDao {
      @Query("SELECT * FROM pages WHERE journalId = :journalId AND deletedAt IS NULL ORDER BY pageIndex ASC")
      fun getByJournalFlow(journalId: String): Flow<List<Page>>
      
      @Query("SELECT * FROM pages WHERE id = :id AND deletedAt IS NULL")
      suspend fun getById(id: String): Page?
      
      @Insert(onConflict = OnConflictStrategy.REPLACE)
      suspend fun insert(page: Page)
      
      @Update
      suspend fun update(page: Page)
      
      @Query("UPDATE pages SET deletedAt = :timestamp WHERE id = :id")
      suspend fun softDelete(id: String, timestamp: Long = System.currentTimeMillis())
  }
  ```

- [ ] **BlockDao** oluştur:
  ```kotlin
  @Dao
  interface BlockDao {
      @Query("SELECT * FROM blocks WHERE pageId = :pageId AND deletedAt IS NULL ORDER BY zIndex ASC")
      fun getByPageFlow(pageId: String): Flow<List<Block>>
      
      @Insert(onConflict = OnConflictStrategy.REPLACE)
      suspend fun insert(block: Block)
      
      @Update
      suspend fun update(block: Block)
      
      @Query("UPDATE blocks SET deletedAt = :timestamp WHERE id = :id")
      suspend fun softDelete(id: String, timestamp: Long = System.currentTimeMillis())
      
      @Query("SELECT MAX(zIndex) FROM blocks WHERE pageId = :pageId")
      suspend fun getMaxZIndex(pageId: String): Int?
  }
  ```

- [ ] **AppDatabase** oluştur:
  ```kotlin
  @Database(
      entities = [Journal::class, Page::class, Block::class],
      version = 1,
      exportSchema = true
  )
  abstract class AppDatabase : RoomDatabase() {
      abstract fun journalDao(): JournalDao
      abstract fun pageDao(): PageDao
      abstract fun blockDao(): BlockDao
      
      companion object {
          @Volatile
          private var INSTANCE: AppDatabase? = null
          
          fun getInstance(context: Context): AppDatabase {
              return INSTANCE ?: synchronized(this) {
                  val instance = Room.databaseBuilder(
                      context.applicationContext,
                      AppDatabase::class.java,
                      "journal_database"
                  )
                  .fallbackToDestructiveMigration() // MVP'de migration yok
                  .build()
                  INSTANCE = instance
                  instance
              }
          }
      }
  }
  ```

**Tamamlanma kriteri:** Database test'i geçiyor, CRUD işlemleri çalışıyor

---

#### Milestone 1.4: Repository Layer
**Süre:** 2 gün

**Görevler:**
- [ ] **JournalRepository** interface:
  ```kotlin
  interface JournalRepository {
      fun getAllJournals(): Flow<List<Journal>>
      suspend fun getJournal(id: String): Journal?
      suspend fun createJournal(title: String): Journal
      suspend fun updateJournal(journal: Journal)
      suspend fun deleteJournal(id: String)
  }
  ```

- [ ] **JournalRepository** implementasyon:
  ```kotlin
  class JournalRepositoryImpl(
      private val journalDao: JournalDao,
      private val pageDao: PageDao
  ) : JournalRepository {
      
      override fun getAllJournals(): Flow<List<Journal>> {
          return journalDao.getAllFlow()
      }
      
      override suspend fun getJournal(id: String): Journal? {
          return journalDao.getById(id)
      }
      
      override suspend fun createJournal(title: String): Journal {
          val journal = Journal(title = title)
          journalDao.insert(journal)
          
          // İlk sayfayı otomatik oluştur
          val firstPage = Page(
              journalId = journal.id,
              pageIndex = 0
          )
          pageDao.insert(firstPage)
          
          return journal
      }
      
      override suspend fun updateJournal(journal: Journal) {
          journalDao.update(journal.copy(updatedAt = System.currentTimeMillis()))
      }
      
      override suspend fun deleteJournal(id: String) {
          journalDao.softDelete(id)
      }
  }
  ```

- [ ] **PageRepository** ve **BlockRepository** benzer şekilde oluştur

**Tamamlanma kriteri:** Repository testleri geçiyor

---

### Sprint 2 (Hafta 3): UI Foundation & Navigation

#### Milestone 2.1: Navigation Setup
**Süre:** 1 gün

**Görevler:**
- [ ] Navigation graph oluştur:
  ```kotlin
  sealed class Screen(val route: String) {
      object Library : Screen("library")
      object JournalView : Screen("journal/{journalId}") {
          fun createRoute(journalId: String) = "journal/$journalId"
      }
      object PageEditor : Screen("editor/{journalId}/{pageId}") {
          fun createRoute(journalId: String, pageId: String) = 
              "editor/$journalId/$pageId"
      }
  }
  
  @Composable
  fun JournalNavHost(
      navController: NavHostController = rememberNavController()
  ) {
      NavHost(navController, startDestination = Screen.Library.route) {
          composable(Screen.Library.route) {
              LibraryScreen(navController)
          }
          composable(
              Screen.JournalView.route,
              arguments = listOf(navArgument("journalId") { type = NavType.StringType })
          ) { backStackEntry ->
              val journalId = backStackEntry.arguments?.getString("journalId")!!
              JournalViewScreen(journalId, navController)
          }
          composable(
              Screen.PageEditor.route,
              arguments = listOf(
                  navArgument("journalId") { type = NavType.StringType },
                  navArgument("pageId") { type = NavType.StringType }
              )
          ) { backStackEntry ->
              val journalId = backStackEntry.arguments?.getString("journalId")!!
              val pageId = backStackEntry.arguments?.getString("pageId")!!
              PageEditorScreen(journalId, pageId, navController)
          }
      }
  }
  ```

**Tamamlanma kriteri:** Ekranlar arası geçiş çalışıyor

---

#### Milestone 2.2: Library Screen (Journal Listesi)
**Süre:** 2-3 gün

**Görevler:**
- [ ] **LibraryViewModel** oluştur:
  ```kotlin
  class LibraryViewModel(
      private val repository: JournalRepository
  ) : ViewModel() {
      
      val journals: StateFlow<List<Journal>> = repository
          .getAllJournals()
          .stateIn(
              scope = viewModelScope,
              started = SharingStarted.WhileSubscribed(5000),
              initialValue = emptyList()
          )
      
      fun createJournal(title: String) {
          viewModelScope.launch {
              repository.createJournal(title)
          }
      }
      
      fun deleteJournal(id: String) {
          viewModelScope.launch {
              repository.deleteJournal(id)
          }
      }
  }
  ```

- [ ] **LibraryScreen** UI:
  ```kotlin
  @Composable
  fun LibraryScreen(
      navController: NavController,
      viewModel: LibraryViewModel = viewModel()
  ) {
      val journals by viewModel.journals.collectAsState()
      var showCreateDialog by remember { mutableStateOf(false) }
      
      Scaffold(
          topBar = {
              TopAppBar(title = { Text("Defterlerim") })
          },
          floatingActionButton = {
              FloatingActionButton(onClick = { showCreateDialog = true }) {
                  Icon(Icons.Default.Add, "Yeni Defter")
              }
          }
      ) { padding ->
          if (journals.isEmpty()) {
              EmptyState()
          } else {
              LazyVerticalGrid(
                  columns = GridCells.Fixed(2),
                  contentPadding = padding
              ) {
                  items(journals) { journal ->
                      JournalCard(
                          journal = journal,
                          onClick = { 
                              navController.navigate(
                                  Screen.JournalView.createRoute(journal.id)
                              )
                          },
                          onDelete = { viewModel.deleteJournal(journal.id) }
                      )
                  }
              }
          }
      }
      
      if (showCreateDialog) {
          CreateJournalDialog(
              onDismiss = { showCreateDialog = false },
              onCreate = { title ->
                  viewModel.createJournal(title)
                  showCreateDialog = false
              }
          )
      }
  }
  ```

- [ ] **JournalCard** composable:
  ```kotlin
  @Composable
  fun JournalCard(
      journal: Journal,
      onClick: () -> Unit,
      onDelete: () -> Unit
  ) {
      Card(
          modifier = Modifier
              .padding(8.dp)
              .fillMaxWidth()
              .aspectRatio(0.7f)
              .clickable(onClick = onClick)
      ) {
          Column {
              // Kapak görseli (şimdilik placeholder)
              Box(
                  modifier = Modifier
                      .fillMaxWidth()
                      .weight(1f)
                      .background(MaterialTheme.colorScheme.primaryContainer)
              ) {
                  Icon(
                      Icons.Default.Book,
                      contentDescription = null,
                      modifier = Modifier
                          .size(64.dp)
                          .align(Alignment.Center)
                  )
              }
              
              // Başlık
              Text(
                  text = journal.title,
                  style = MaterialTheme.typography.titleMedium,
                  modifier = Modifier.padding(12.dp),
                  maxLines = 2,
                  overflow = TextOverflow.Ellipsis
              )
              
              // Sil butonu
              IconButton(
                  onClick = onDelete,
                  modifier = Modifier.align(Alignment.End)
              ) {
                  Icon(Icons.Default.Delete, "Sil")
              }
          }
      }
  }
  ```

- [ ] **CreateJournalDialog**:
  ```kotlin
  @Composable
  fun CreateJournalDialog(
      onDismiss: () -> Unit,
      onCreate: (String) -> Unit
  ) {
      var title by remember { mutableStateOf("") }
      
      AlertDialog(
          onDismissRequest = onDismiss,
          title = { Text("Yeni Defter") },
          text = {
              OutlinedTextField(
                  value = title,
                  onValueChange = { title = it },
                  label = { Text("Defter Adı") },
                  singleLine = true
              )
          },
          confirmButton = {
              TextButton(
                  onClick = { onCreate(title) },
                  enabled = title.isNotBlank()
              ) {
                  Text("Oluştur")
              }
          },
          dismissButton = {
              TextButton(onClick = onDismiss) {
                  Text("İptal")
              }
          }
      )
  }
  ```

**Tamamlanma kriteri:** Journal oluşturma, listeleme, silme çalışıyor

---

#### Milestone 2.3: Journal View Screen (Sayfa Çevirme)
**Süre:** 3 gün

**Görevler:**
- [ ] **JournalViewModel** oluştur:
  ```kotlin
  class JournalViewModel(
      private val journalId: String,
      private val journalRepository: JournalRepository,
      private val pageRepository: PageRepository
  ) : ViewModel() {
      
      val journal: StateFlow<Journal?> = flow {
          emit(journalRepository.getJournal(journalId))
      }.stateIn(viewModelScope, SharingStarted.Lazily, null)
      
      val pages: StateFlow<List<Page>> = pageRepository
          .getPagesForJournal(journalId)
          .stateIn(viewModelScope, SharingStarted.Lazily, emptyList())
      
      private val _currentPageIndex = MutableStateFlow(0)
      val currentPageIndex: StateFlow<Int> = _currentPageIndex
      
      fun addPage() {
          viewModelScope.launch {
              val newIndex = pages.value.size
              pageRepository.createPage(journalId, newIndex)
          }
      }
      
      fun goToPage(index: Int) {
          if (index in pages.value.indices) {
              _currentPageIndex.value = index
          }
      }
      
      fun nextPage() {
          val next = _currentPageIndex.value + 1
          if (next < pages.value.size) {
              _currentPageIndex.value = next
          }
      }
      
      fun previousPage() {
          val prev = _currentPageIndex.value - 1
          if (prev >= 0) {
              _currentPageIndex.value = prev
          }
      }
  }
  ```

- [ ] **JournalViewScreen** UI:
  ```kotlin
  @Composable
  fun JournalViewScreen(
      journalId: String,
      navController: NavController,
      viewModel: JournalViewModel = viewModel(
          factory = JournalViewModelFactory(journalId)
      )
  ) {
      val journal by viewModel.journal.collectAsState()
      val pages by viewModel.pages.collectAsState()
      val currentPageIndex by viewModel.currentPageIndex.collectAsState()
      
      Scaffold(
          topBar = {
              TopAppBar(
                  title = { Text(journal?.title ?: "") },
                  navigationIcon = {
                      IconButton(onClick = { navController.popBackStack() }) {
                          Icon(Icons.Default.ArrowBack, "Geri")
                      }
                  },
                  actions = {
                      IconButton(onClick = { viewModel.addPage() }) {
                          Icon(Icons.Default.Add, "Sayfa Ekle")
                      }
                  }
              )
          }
      ) { padding ->
          if (pages.isEmpty()) {
              Box(
                  modifier = Modifier.fillMaxSize(),
                  contentAlignment = Alignment.Center
              ) {
                  Text("Sayfa yükleniyor...")
              }
          } else {
              Column(modifier = Modifier.padding(padding)) {
                  // Sayfa gösterimi
                  PagePager(
                      pages = pages,
                      currentIndex = currentPageIndex,
                      onPageChange = { viewModel.goToPage(it) },
                      onPageClick = { page ->
                          navController.navigate(
                              Screen.PageEditor.createRoute(journalId, page.id)
                          )
                      },
                      modifier = Modifier.weight(1f)
                  )
                  
                  // Sayfa göstergesi
                  PageIndicator(
                      pageCount = pages.size,
                      currentPage = currentPageIndex,
                      onPageClick = { viewModel.goToPage(it) }
                  )
              }
          }
      }
  }
  ```

- [ ] **PagePager** (swipe gesture ile sayfa çevirme):
  ```kotlin
  @Composable
  fun PagePager(
      pages: List<Page>,
      currentIndex: Int,
      onPageChange: (Int) -> Unit,
      onPageClick: (Page) -> Unit,
      modifier: Modifier = Modifier
  ) {
      val pagerState = rememberPagerState(
          initialPage = currentIndex,
          pageCount = { pages.size }
      )
      
      LaunchedEffect(pagerState.currentPage) {
          if (pagerState.currentPage != currentIndex) {
              onPageChange(pagerState.currentPage)
          }
      }
      
      HorizontalPager(
          state = pagerState,
          modifier = modifier
      ) { pageIndex ->
          val page = pages[pageIndex]
          
          PagePreview(
              page = page,
              onClick = { onPageClick(page) }
          )
      }
  }
  ```

- [ ] **PagePreview** (sayfa önizleme):
  ```kotlin
  @Composable
  fun PagePreview(
      page: Page,
      onClick: () -> Unit
  ) {
      Card(
          modifier = Modifier
              .fillMaxSize()
              .padding(16.dp)
              .clickable(onClick = onClick),
          elevation = CardDefaults.cardElevation(8.dp)
      ) {
          Box(
              modifier = Modifier
                  .fillMaxSize()
                  .background(Color.White)
                  .padding(16.dp)
          ) {
              // Şimdilik placeholder
              Text(
                  text = "Sayfa ${page.pageIndex + 1}",
                  style = MaterialTheme.typography.headlineMedium,
                  modifier = Modifier.align(Alignment.Center)
              )
              
              Text(
                  text = "Düzenlemek için dokun",
                  style = MaterialTheme.typography.bodySmall,
                  modifier = Modifier
                      .align(Alignment.BottomCenter)
                      .padding(bottom = 16.dp)
              )
          }
      }
  }
  ```

- [ ] **PageIndicator** (alt bar):
  ```kotlin
  @Composable
  fun PageIndicator(
      pageCount: Int,
      currentPage: Int,
      onPageClick: (Int) -> Unit
  ) {
      Row(
          modifier = Modifier
              .fillMaxWidth()
              .padding(16.dp),
          horizontalArrangement = Arrangement.Center
      ) {
          repeat(pageCount) { index ->
              Box(
                  modifier = Modifier
                      .size(if (index == currentPage) 12.dp else 8.dp)
                      .padding(4.dp)
                      .background(
                          color = if (index == currentPage) 
                              MaterialTheme.colorScheme.primary
                          else 
                              MaterialTheme.colorScheme.onSurface.copy(alpha = 0.3f),
                          shape = CircleShape
                      )
                      .clickable { onPageClick(index) }
              )
          }
      }
  }
  ```

**Tamamlanma kriteri:** Sayfa çevirme smooth çalışıyor, sayfa ekleme/görüntüleme çalışıyor

---

### Sprint 3 (Hafta 4-5): Page Editor & Block System

#### Milestone 3.1: Page Editor Foundation
**Süre:** 2 gün

**Görevler:**
- [ ] **PageEditorViewModel** oluştur:
  ```kotlin
  class PageEditorViewModel(
      private val journalId: String,
      private val pageId: String,
      private val pageRepository: PageRepository,
      private val blockRepository: BlockRepository
  ) : ViewModel() {
      
      val page: StateFlow<Page?> = flow {
          emit(pageRepository.getPage(pageId))
      }.stateIn(viewModelScope, SharingStarted.Lazily, null)
      
      val blocks: StateFlow<List<Block>> = blockRepository
          .getBlocksForPage(pageId)
          .stateIn(viewModelScope, SharingStarted.Lazily, emptyList())
      
      private val _selectedBlockId = MutableStateFlow<String?>(null)
      val selectedBlockId: StateFlow<String?> = _selectedBlockId
      
      private val _editMode = MutableStateFlow(false)
      val editMode: StateFlow<Boolean> = _editMode
      
      fun selectBlock(blockId: String?) {
          _selectedBlockId.value = blockId
      }
      
      fun addTextBlock(x: Float, y: Float) {
          viewModelScope.launch {
              val data = BlockData.Text(content = "").toJson()
              blockRepository.createBlock(
                  pageId = pageId,
                  type = BlockType.TEXT,
                  x = x,
                  y = y,
                  width = 200f,
                  height = 100f,
                  data = data
              )
          }
      }
      
      fun updateBlock(block: Block) {
          viewModelScope.launch {
              blockRepository.updateBlock(block)
          }
      }
      
      fun deleteBlock(blockId: String) {
          viewModelScope.launch {
              blockRepository.deleteBlock(blockId)
          }
      }
      
      fun moveBlock(blockId: String, newX: Float, newY: Float) {
          viewModelScope.launch {
              val block = blocks.value.find { it.id == blockId } ?: return@launch
              blockRepository.updateBlock(
                  block.copy(x = newX, y = newY)
              )
          }
      }
  }
  ```

- [ ] **PageEditorScreen** temel yapı:
  ```kotlin
  @Composable
  fun PageEditorScreen(
      journalId: String,
      pageId: String,
      navController: NavController,
      viewModel: PageEditorViewModel = viewModel(
          factory = PageEditorViewModelFactory(journalId, pageId)
      )
  ) {
      val page by viewModel.page.collectAsState()
      val blocks by viewModel.blocks.collectAsState()
      val selectedBlockId by viewModel.selectedBlockId.collectAsState()
      
      Scaffold(
          topBar = {
              TopAppBar(
                  title = { Text("Sayfa Düzenle") },
                  navigationIcon = {
                      IconButton(onClick = { navController.popBackStack() }) {
                          Icon(Icons.Default.ArrowBack, "Geri")
                      }
                  }
              )
          },
          bottomBar = {
              EditorToolbar(
                  onAddText = { viewModel.addTextBlock(100f, 100f) },
                  onAddImage = { /* TODO */ },
                  onAddHandwriting = { /* TODO */ }
              )
          }
      ) { padding ->
          EditorCanvas(
              page = page,
              blocks = blocks,
              selectedBlockId = selectedBlockId,
              onBlockSelected = { viewModel.selectBlock(it) },
              onBlockMoved = { blockId, x, y -> viewModel.moveBlock(blockId, x, y) },
              modifier = Modifier.padding(padding)
          )
      }
  }
  ```

**Tamamlanma kriteri:** Editor ekranı açılıyor, temel yapı hazır

---

#### Milestone 3.2: Canvas & Gesture System
**Süre:** 3-4 gün (En kritik kısım!)

**Görevler:**
- [ ] **EditorCanvas** composable:
  ```kotlin
  @Composable
  fun EditorCanvas(
      page: Page?,
      blocks: List<Block>,
      selectedBlockId: String?,
      onBlockSelected: (String?) -> Unit,
      onBlockMoved: (blockId: String, x: Float, y: Float) -> Unit,
      modifier: Modifier = Modifier
  ) {
      var draggedBlockId by remember { mutableStateOf<String?>(null) }
      var dragOffset by remember { mutableStateOf(Offset.Zero) }
      
      Box(
          modifier = modifier
              .fillMaxSize()
              .background(Color.White)
              .pointerInput(Unit) {
                  detectTapGestures(
                      onTap = { offset ->
                          // Boş alana tıklandı, seçimi kaldır
                          val tappedBlock = findBlockAtPosition(blocks, offset)
                          onBlockSelected(tappedBlock?.id)
                      },
                      onLongPress = { offset ->
                          // Uzun basma - block ekle menüsü
                          // TODO: Show add block menu
                      }
                  )
              }
              .pointerInput(Unit) {
                  detectDragGestures(
                      onDragStart = { offset ->
                          val block = findBlockAtPosition(blocks, offset)
                          if (block != null) {
                              draggedBlockId = block.id
                              dragOffset = Offset(offset.x - block.x, offset.y - block.y)
                              onBlockSelected(block.id)
                          }
                      },
                      onDrag = { change, _ ->
                          draggedBlockId?.let { blockId ->
                              val newX = change.position.x - dragOffset.x
                              val newY = change.position.y - dragOffset.y
                              onBlockMoved(blockId, newX, newY)
                          }
                      },
                      onDragEnd = {
                          draggedBlockId = null
                      }
                  )
              }
      ) {
          // Render tüm block'lar
          blocks.forEach { block ->
              BlockRenderer(
                  block = block,
                  isSelected = block.id == selectedBlockId,
                  modifier = Modifier.offset { 
                      IntOffset(block.x.roundToInt(), block.y.roundToInt()) 
                  }
              )
          }
      }
  }
  
  private fun findBlockAtPosition(blocks: List<Block>, offset: Offset): Block? {
      // Z-index'e göre tersten ara (en üstteki önce)
      return blocks
          .sortedByDescending { it.zIndex }
          .firstOrNull { block ->
              offset.x >= block.x &&
              offset.x <= block.x + block.width &&
              offset.y >= block.y &&
              offset.y <= block.y + block.height
          }
  }
  ```

- [ ] **BlockRenderer** (block tipine göre render):
  ```kotlin
  @Composable
  fun BlockRenderer(
      block: Block,
      isSelected: Boolean,
      modifier: Modifier = Modifier
  ) {
      Box(
          modifier = modifier
              .size(block.width.dp, block.height.dp)
              .border(
                  width = if (isSelected) 2.dp else 0.dp,
                  color = if (isSelected) MaterialTheme.colorScheme.primary else Color.Transparent
              )
      ) {
          when (block.type) {
              BlockType.TEXT -> TextBlockRenderer(block)
              BlockType.IMAGE -> ImageBlockRenderer(block)
              BlockType.HANDWRITING -> HandwritingBlockRenderer(block)
          }
          
          // Selection handles
          if (isSelected) {
              SelectionHandles(block)
          }
      }
  }
  ```

**Tamamlanma kriteri:** Block'ları sürükleyip taşıyabiliyoruz

---

#### Milestone 3.3: Text Block
**Süre:** 2 gün

**Görevler:**
- [ ] **TextBlockRenderer**:
  ```kotlin
  @Composable
  fun TextBlockRenderer(block: Block) {
      val data = block.data.toBlockData() as? BlockData.Text ?: return
      var isEditing by remember { mutableStateOf(false) }
      var text by remember { mutableStateOf(data.content) }
      
      if (isEditing) {
          BasicTextField(
              value = text,
              onValueChange = { text = it },
              textStyle = TextStyle(
                  fontSize = data.fontSize.sp,
                  color = Color(android.graphics.Color.parseColor(data.color))
              ),
              modifier = Modifier
                  .fillMaxSize()
                  .padding(8.dp)
          )
      } else {
          Text(
              text = data.content.ifEmpty { "Metin gir" },
              fontSize = data.fontSize.sp,
              color = Color(android.graphics.Color.parseColor(data.color)),
              modifier = Modifier
                  .fillMaxSize()
                  .padding(8.dp)
                  .clickable { isEditing = true }
          )
      }
  }
  ```

- [ ] Text düzenleme UI (klavye, focus management)

**Tamamlanma kriteri:** Text block eklenip düzenlenebiliyor

---

#### Milestone 3.4: Image Block
**Süre:** 2 gün

**Görevler:**
- [ ] **ImagePicker** helper:
  ```kotlin
  @Composable
  fun rememberImagePicker(
      onImageSelected: (Uri) -> Unit
  ): () -> Unit {
      val launcher = rememberLauncherForActivityResult(
          ActivityResultContracts.GetContent()
      ) { uri ->
          uri?.let { onImageSelected(it) }
      }
      
      return { launcher.launch("image/*") }
  }
  ```

- [ ] **Image storage helper**:
  ```kotlin
  object ImageStorage {
      suspend fun saveImage(context: Context, uri: Uri, blockId: String): String {
          val inputStream = context.contentResolver.openInputStream(uri)
          val file = File(context.filesDir, "blocks/$blockId.jpg")
          file.parentFile?.mkdirs()
          
          inputStream?.use { input ->
              file.outputStream().use { output ->
                  input.copyTo(output)
              }
          }
          
          return file.absolutePath
      }
      
      fun loadImage(filePath: String): Bitmap? {
          return BitmapFactory.decodeFile(filePath)
      }
  }
  ```

- [ ] **ImageBlockRenderer**:
  ```kotlin
  @Composable
  fun ImageBlockRenderer(block: Block) {
      val data = block.data.toBlockData() as? BlockData.Image ?: return
      
      AsyncImage(
          model = ImageRequest.Builder(LocalContext.current)
              .data(File(data.filePath))
              .crossfade(true)
              .build(),
          contentDescription = null,
          contentScale = ContentScale.Fit,
          modifier = Modifier.fillMaxSize()
      )
  }
  ```

- [ ] Image ekleme flow'u editor'a entegre et

**Tamamlanma kriteri:** Galeriden resim seçip sayfaya eklenebiliyor

---

#### Milestone 3.5: Handwriting Block (Basit versiyon)
**Süre:** 2-3 gün

**Görevler:**
- [ ] **Stroke data model**:
  ```kotlin
  data class Stroke(
      val points: List<Offset>,
      val color: String = "#000000",
      val strokeWidth: Float = 3f
  )
  
  data class HandwritingData(
      val strokes: List<Stroke>
  )
  ```

- [ ] **HandwritingCanvas** composable:
  ```kotlin
  @Composable
  fun HandwritingCanvas(
      initialStrokes: List<Stroke>,
      onStrokesChanged: (List<Stroke>) -> Unit,
      modifier: Modifier = Modifier
  ) {
      val strokes = remember { mutableStateListOf<Stroke>().apply { addAll(initialStrokes) } }
      var currentStroke = remember { mutableListOf<Offset>() }
      
      Canvas(
          modifier = modifier
              .fillMaxSize()
              .pointerInput(Unit) {
                  detectDragGestures(
                      onDragStart = { offset ->
                          currentStroke.clear()
                          currentStroke.add(offset)
                      },
                      onDrag = { change, _ ->
                          currentStroke.add(change.position)
                      },
                      onDragEnd = {
                          if (currentStroke.isNotEmpty()) {
                              strokes.add(Stroke(currentStroke.toList()))
                              onStrokesChanged(strokes.toList())
                              currentStroke.clear()
                          }
                      }
                  )
              }
      ) {
          // Tamamlanmış stroke'ları çiz
          strokes.forEach { stroke ->
              drawStroke(stroke)
          }
          
          // Aktif stroke'u çiz
          if (currentStroke.size > 1) {
              drawPath(
                  path = Path().apply {
                      moveTo(currentStroke[0].x, currentStroke[0].y)
                      currentStroke.drop(1).forEach { point ->
                          lineTo(point.x, point.y)
                      }
                  },
                  color = Color.Black,
                  style = Stroke(width = 3f)
              )
          }
      }
  }
  
  private fun DrawScope.drawStroke(stroke: Stroke) {
      if (stroke.points.size < 2) return
      
      drawPath(
          path = Path().apply {
              moveTo(stroke.points[0].x, stroke.points[0].y)
              stroke.points.drop(1).forEach { point ->
                  lineTo(point.x, point.y)
              }
          },
          color = Color(android.graphics.Color.parseColor(stroke.color)),
          style = Stroke(width = stroke.strokeWidth)
      )
  }
  ```

- [ ] **HandwritingBlockRenderer**:
  ```kotlin
  @Composable
  fun HandwritingBlockRenderer(block: Block) {
      val data = try {
          Json.decodeFromString<HandwritingData>(block.data)
      } catch (e: Exception) {
          HandwritingData(emptyList())
      }
      
      Canvas(modifier = Modifier.fillMaxSize()) {
          data.strokes.forEach { stroke ->
              drawStroke(stroke)
          }
      }
  }
  ```

**Tamamlanma kriteri:** Parmakla çizim yapılabiliyor, kaydediliyor

---

### Sprint 4 (Hafta 6): Polish & Testing

#### Milestone 4.1: Auto-Save System
**Süre:** 1-2 gün

**Görevler:**
- [ ] **AutoSaveManager**:
  ```kotlin
  class AutoSaveManager(
      private val scope: CoroutineScope
  ) {
      private var saveJob: Job? = null
      private val _isSaving = MutableStateFlow(false)
      val isSaving: StateFlow<Boolean> = _isSaving
      
      private val _lastSaveTime = MutableStateFlow<Long?>(null)
      val lastSaveTime: StateFlow<Long?> = _lastSaveTime
      
      fun scheduleSave(save: suspend () -> Unit) {
          saveJob?.cancel()
          saveJob = scope.launch {
              delay(2000) // 2 saniye debounce
              _isSaving.value = true
              try {
                  save()
                  _lastSaveTime.value = System.currentTimeMillis()
              } finally {
                  _isSaving.value = false
              }
          }
      }
  }
  ```

- [ ] Editor'a entegre et:
  ```kotlin
  // PageEditorViewModel içinde
  private val autoSaveManager = AutoSaveManager(viewModelScope)
  
  fun updateBlock(block: Block) {
      autoSaveManager.scheduleSave {
          blockRepository.updateBlock(block)
      }
  }
  ```

- [ ] **SaveIndicator** UI:
  ```kotlin
  @Composable
  fun SaveIndicator(
      isSaving: Boolean,
      lastSaveTime: Long?
  ) {
      Row(
          horizontalArrangement = Arrangement.spacedBy(4.dp),
          verticalAlignment = Alignment.CenterVertically
      ) {
          if (isSaving) {
              CircularProgressIndicator(modifier = Modifier.size(16.dp))
              Text("Kaydediliyor...", style = MaterialTheme.typography.bodySmall)
          } else if (lastSaveTime != null) {
              Icon(
                  Icons.Default.Check,
                  contentDescription = null,
                  modifier = Modifier.size(16.dp),
                  tint = Color.Green
              )
              Text("Kaydedildi", style = MaterialTheme.typography.bodySmall)
          }
      }
  }
  ```

**Tamamlanma kriteri:** Değişiklikler otomatik kaydediliyor, kullanıcı görebiliyor

---

#### Milestone 4.2: Undo/Redo System
**Süre:** 2 gün

**Görevler:**
- [ ] **Command interface**:
  ```kotlin
  interface Command {
      suspend fun execute()
      suspend fun undo()
  }
  ```

- [ ] **MoveBlockCommand**:
  ```kotlin
  class MoveBlockCommand(
      private val blockRepository: BlockRepository,
      private val blockId: String,
      private val oldX: Float,
      private val oldY: Float,
      private val newX: Float,
      private val newY: Float
  ) : Command {
      override suspend fun execute() {
          blockRepository.updatePosition(blockId, newX, newY)
      }
      
      override suspend fun undo() {
          blockRepository.updatePosition(blockId, oldX, oldY)
      }
  }
  ```

- [ ] **CommandHistory**:
  ```kotlin
  class CommandHistory {
      private val history = mutableListOf<Command>()
      private var currentIndex = -1
      
      suspend fun execute(command: Command) {
          // İlerideki komutları temizle
          while (history.size > currentIndex + 1) {
              history.removeAt(history.size - 1)
          }
          
          command.execute()
          history.add(command)
          currentIndex++
      }
      
      suspend fun undo() {
          if (canUndo()) {
              history[currentIndex].undo()
              currentIndex--
          }
      }
      
      suspend fun redo() {
          if (canRedo()) {
              currentIndex++
              history[currentIndex].execute()
          }
      }
      
      fun canUndo() = currentIndex >= 0
      fun canRedo() = currentIndex < history.size - 1
  }
  ```

- [ ] ViewModel'e entegre et
- [ ] Undo/Redo butonları ekle

**Tamamlanma kriteri:** Undo/Redo çalışıyor

---

#### Milestone 4.3: First Time User Experience
**Süre:** 1-2 gün

**Görevler:**
- [ ] **OnboardingScreen**:
  ```kotlin
  @Composable
  fun OnboardingScreen(
      onComplete: () -> Unit
  ) {
      var step by remember { mutableStateOf(0) }
      
      Column(
          modifier = Modifier
              .fillMaxSize()
              .padding(24.dp),
          verticalArrangement = Arrangement.SpaceBetween
      ) {
          when (step) {
              0 -> OnboardingStep1()
              1 -> OnboardingStep2()
              2 -> OnboardingStep3()
          }
          
          Row(
              modifier = Modifier.fillMaxWidth(),
              horizontalArrangement = Arrangement.SpaceBetween
          ) {
              TextButton(onClick = onComplete) {
                  Text("Atla")
              }
              
              Button(
                  onClick = {
                      if (step < 2) step++ else onComplete()
                  }
              ) {
                  Text(if (step < 2) "İleri" else "Başla")
              }
          }
      }
  }
  ```

- [ ] Uygulama ilk açılışta göster

**Tamamlanma kriteri:** İlk kullanıcı deneyimi akıcı

---

#### Milestone 4.4: Performance Optimization
**Süre:** 2 gün

**Görevler:**
- [ ] **Block caching**:
  ```kotlin
  class BlockRenderCache {
      private val cache = LruCache<String, Bitmap>(20)
      
      fun get(blockId: String): Bitmap? = cache.get(blockId)
      
      fun put(blockId: String, bitmap: Bitmap) {
          cache.put(blockId, bitmap)
      }
      
      fun invalidate(blockId: String) {
          cache.remove(blockId)
      }
  }
  ```

- [ ] Canvas render optimizasyonu
- [ ] Memory profiling
- [ ] Frame rate ölçümü (60 FPS hedef)

**Tamamlanma kriteri:** 30+ block'lu sayfada 60 FPS korunuyor

---

#### Milestone 4.5: Error Handling & Crash Recovery
**Süre:** 1 gün

**Görevler:**
- [ ] **Emergency backup**:
  ```kotlin
  class EmergencyBackup(private val context: Context) {
      fun save(journal: Journal, pages: List<Page>, blocks: List<Block>) {
          val backupFile = File(context.cacheDir, "emergency_${journal.id}.json")
          val data = mapOf(
              "journal" to journal,
              "pages" to pages,
              "blocks" to blocks
          )
          backupFile.writeText(Json.encodeToString(data))
      }
      
      fun checkAndRestore(): List<Journal>? {
          // Uygulama açılırken kontrol et
      }
  }
  ```

- [ ] Crash'ten sonra recovery dialog

**Tamamlanma kriteri:** Crash durumunda veri kaybı yok

---

#### Milestone 4.6: Testing
**Süre:** 2-3 gün

**Görevler:**
- [ ] **Unit tests**:
  - Repository CRUD testleri
  - Command pattern testleri
  - Data model testleri
  
- [ ] **Integration tests**:
  - Journal oluşturma flow
  - Block ekleme flow
  - Auto-save çalışması

- [ ] **Manual testing checklist**:
  ```markdown
  ## Temel İşlevler
  - [ ] Journal oluşturma
  - [ ] Sayfa ekleme
  - [ ] Text block ekleme ve düzenleme
  - [ ] Image block ekleme
  - [ ] Handwriting çizim
  - [ ] Block taşıma
  - [ ] Block silme
  - [ ] Undo/Redo
  
  ## Veri Kalıcılığı
  - [ ] Uygulama kapatıp açma
  - [ ] Çok sayıda journal (10+)
  - [ ] Çok sayıda sayfa (50+)
  - [ ] Çok sayıda block (30+/sayfa)
  
  ## Performance
  - [ ] Sayfa çevirme smooth mu?
  - [ ] Block taşıma smooth mu?
  - [ ] Handwriting lag var mı?
  - [ ] Low-end cihazda test (4GB RAM)
  
  ## Edge Cases
  - [ ] Boş journal
  - [ ] Boş sayfa
  - [ ] Çok uzun metin
  - [ ] Çok büyük resim
  - [ ] Internet kesilmesi (olmamalı çünkü offline)
  - [ ] Düşük disk alanı
  ```

**Tamamlanma kriteri:** Tüm kritik testler geçiyor

---

## 🚀 DEPLOYMENT HAZIRLIĞI

### Build Variants
```gradle
android {
    buildTypes {
        debug {
            applicationIdSuffix ".debug"
            debuggable true
        }
        release {
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt')
        }
    }
}
```

### Beta Dağıtımı
1. **Internal Testing** (5-10 kişi):
   - Google Play Console → Internal testing
   - Test süresi: 1 hafta
   - Feedback formu: Google Forms

2. **Closed Beta** (50-100 kişi):
   - Play Store beta track
   - Test süresi: 2 hafta
   - Analytics: Firebase Analytics (temel metrikler)

### Beta Test Metrikleri
```kotlin
// Firebase Analytics events
analytics.logEvent("journal_created") { /* ... */ }
analytics.logEvent("page_added") { /* ... */ }
analytics.logEvent("block_added") { param("type", blockType) }
analytics.logEvent("app_crash") { /* ... */ }
```

---

## 📊 BAŞARI KRİTERLERİ (TEKRAR)

### Teknik
- [ ] Crash rate < 1%
- [ ] ANR rate < 0.5%
- [ ] Sayfa çevirme: 60 FPS
- [ ] Block taşıma: 60 FPS
- [ ] Uygulama açılış: < 2 saniye

### Kullanıcı
- [ ] 3 günde en az 1 journal oluşturma oranı: >70%
- [ ] İlk haftada geri dönüş oranı: >40%
- [ ] İlk sayfayı doldurmadan çıkma oranı: <30%
- [ ] Beta kullanıcılarının 5 üzerinden puan ortalaması: >3.5

### Fonksiyonel
- [ ] Offline tam çalışıyor
- [ ] Tüm block türleri çalışıyor
- [ ] Undo/Redo çalışıyor
- [ ] Auto-save çalışıyor
- [ ] Crash recovery çalışıyor

---

## 🎓 ÖĞRENİLECEKLER

Bu MVP'yi tamamladıktan sonra şunları öğrenmiş olursunuz:

### Teknik
- Room Database ile kompleks ilişkili veri modelleme
- Jetpack Compose ile custom canvas ve gesture handling
- Command pattern ile undo/redo implementasyonu
- Repository pattern ile clean architecture
- Performance optimization (rendering, memory)

### Ürün
- Offline-first uygulama tasarımı
- Kullanıcı onboarding stratejileri
- Beta testing süreci
- Crash recovery ve veri güvenliği

---

## 📝 SONRAKI ADIMLAR (Faz 2'ye Hazırlık)

MVP tamamlandıktan sonra:

1. **Beta feedback topla**
   - Hangi özellikler en çok kullanılıyor?
   - Hangi noktada kullanıcılar takılıyor?
   - Hangi özellik istekleri geliyor?

2. **Veri modeli review**
   - Migration stratejisi planla
   - Tema sistemi için schema değişiklikleri

3. **Faz 2 planlama**
   - Tema sistemi detaylandırma
   - Polaroid frame implementasyonu
   - Ses bloğu araştırması

---

## 🔧 KAYNAKLAR

### Dokümantasyon
- [Jetpack Compose](https://developer.android.com/jetpack/compose)
- [Room Database](https://developer.android.com/training/data-storage/room)
- [Canvas & Gestures](https://developer.android.com/jetpack/compose/graphics)

### Örnek Projeler
- [Compose Samples](https://github.com/android/compose-samples)
- [Notetaking App Sample](https://github.com/android/architecture-samples)

### Tasarım İlhamı
- Dribbble: "journal app", "note taking"
- Pinterest: "bullet journal", "scrapbook"

---

## ✅ CHECKPOINT'LER

Her milestone sonunda kendinize şu soruları sorun:

1. **Bu milestone'un hedefi tam olarak karşılandı mı?**
2. **Kod kalitesi kabul edilebilir mi? (Teknik borç var mı?)**
3. **Performance hedefleri tutturuldu mu?**
4. **Kullanıcı deneyimi tatmin edici mi?**

Eğer cevaplar "hayır" ise, bir sonraki milestone'a geçmeden düzeltin!

---

# 🎯 SON SÖZ

Bu MVP planı **agresif ama gerçekçi**. 6 hafta içinde çalışan, kullanılabilir bir journal uygulaması çıkarabilirsiniz.

**En önemli kural:** Perfect değil, working olsun. MVP'nin amacı mükemmel ürün değil, öğrenmek ve doğrulamaktır.

Başarılar! 🚀