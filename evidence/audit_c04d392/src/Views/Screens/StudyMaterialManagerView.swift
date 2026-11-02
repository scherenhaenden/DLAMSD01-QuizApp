import SwiftUI
import UniformTypeIdentifiers

/// Dedicated management interface for creating, editing, deleting, and importing
/// dynamic study categories and custom questions.
public struct StudyMaterialManagerView: View {
    @ObservedObject var viewModel: QuizViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab: Int = 0
    @State private var showAddCategorySheet = false
    @State private var showEditCategorySheet = false
    @State private var categoryToEdit: QuizCategory? = nil
    @State private var showQuestionEditorSheet = false
    @State private var questionToEdit: Question? = nil
    
    // Import state
    @State private var importURLString: String = ""
    @State private var isDownloading = false
    @State private var statusMessage: String?
    @State private var isStatusError = false
    @State private var showFileImporter = false
    
    // Category filter for questions tab
    @State private var selectedCategoryFilter: String = "all"
    
    public init(
        viewModel: QuizViewModel,
        initialTab: Int = 0,
        initialStatusMessage: String? = nil,
        initialIsStatusError: Bool = false,
        initialCategoryFilter: String = "all",
        initialImportURL: String = "",
        initialIsDownloading: Bool = false,
        initialShowAddCategory: Bool = false,
        initialCategoryToEdit: QuizCategory? = nil,
        initialShowQuestionEditor: Bool = false,
        initialQuestionToEdit: Question? = nil
    ) {
        self.viewModel = viewModel
        self._selectedTab = State(initialValue: initialTab)
        self._statusMessage = State(initialValue: initialStatusMessage)
        self._isStatusError = State(initialValue: initialIsStatusError)
        self._selectedCategoryFilter = State(initialValue: initialCategoryFilter)
        self._importURLString = State(initialValue: initialImportURL)
        self._isDownloading = State(initialValue: initialIsDownloading)
        self._showAddCategorySheet = State(initialValue: initialShowAddCategory)
        self._categoryToEdit = State(initialValue: initialCategoryToEdit)
        self._showQuestionEditorSheet = State(initialValue: initialShowQuestionEditor)
        self._questionToEdit = State(initialValue: initialQuestionToEdit)
    }
    
    var feedbackBannerView: some View { feedbackBanner }
    var subjectsTabView: some View { subjectsTab }
    var questionsTabView: some View { questionsTab }
    var importTabView: some View { importTab }
    
    func presentAddCategorySheet() -> AddCategorySheet {
        addCategorySheetView
    }
    
    func presentEditCategorySheet(for category: QuizCategory) -> EditCategorySheet {
        editCategorySheetView(for: category)
    }
    
    func presentQuestionEditorSheet() -> QuestionEditorSheet {
        questionEditorSheetView
    }
    
    var addCategorySheetView: AddCategorySheet {
        AddCategorySheet(viewModel: viewModel, onCompletion: handleAddCategoryCompletion)
    }
    
    func editCategorySheetView(for category: QuizCategory) -> EditCategorySheet {
        EditCategorySheet(viewModel: viewModel, category: category, onCompletion: handleEditCategoryCompletion)
    }
    
    var questionEditorSheetView: QuestionEditorSheet {
        QuestionEditorSheet(
            viewModel: viewModel,
            editingQuestion: questionToEdit,
            initialCategoryId: (selectedCategoryFilter != "all") ? selectedCategoryFilter : nil,
            onCompletion: handleQuestionEditorCompletion
        )
    }
    
    func handleAddCategoryCompletion(success: Bool, message: String) {
        self.isStatusError = !success
        self.statusMessage = message
    }
    
    func handleEditCategoryCompletion(success: Bool, message: String) {
        self.isStatusError = !success
        self.statusMessage = message
        self.categoryToEdit = nil
    }
    
    func handleQuestionEditorCompletion(success: Bool, message: String) {
        self.isStatusError = !success
        self.statusMessage = message
        self.questionToEdit = nil
    }

    func handleOnAppear() {
        if let warning = viewModel.lastLoadWarning, statusMessage == nil {
            self.statusMessage = warning
            self.isStatusError = warning.contains("CRITICAL")
        }
    }
    
    func triggerDismiss() {
        dismiss()
    }
    
    func clearStatusMessage() {
        statusMessage = nil
    }
    
    func openAddCategory() {
        showAddCategorySheet = true
    }
    
    func openEditCategory(_ category: QuizCategory) {
        categoryToEdit = category
        showEditCategorySheet = true
    }
    
    func openAddQuestion() {
        questionToEdit = nil
        showQuestionEditorSheet = true
    }
    
    func openEditQuestion(_ question: Question) {
        questionToEdit = question
        showQuestionEditorSheet = true
    }
    
    func openFileImporter() {
        showFileImporter = true
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented Control Header
                Picker("Section", selection: $selectedTab) {
                    Text("Subjects").tag(0)
                    Text("Questions").tag(1)
                    Text("Import").tag(2)
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("studyMaterial.segmentedPicker")
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                feedbackBanner
                
                // Tab Content
                Group {
                    switch selectedTab {
                    case 0:
                        subjectsTab
                    case 1:
                        questionsTab
                    default:
                        importTab
                    }
                }
                .frame(maxWidth: 640)
            }
            .background(Color.adaptiveBackground.ignoresSafeArea())
            .navigationTitle("Study Material")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", action: triggerDismiss)
                    .font(.body.bold())
                    .frame(minHeight: 44)
                    .accessibilityIdentifier("studyMaterial.doneButton")
                }
            }
            .sheet(isPresented: $showAddCategorySheet, content: presentAddCategorySheet)
            .sheet(item: $categoryToEdit, content: presentEditCategorySheet)
            .sheet(isPresented: $showQuestionEditorSheet, content: presentQuestionEditorSheet)
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false,
                onCompletion: handleFileImport
            )
            .onAppear(perform: handleOnAppear)
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var feedbackBanner: some View {
        if let message = statusMessage {
            HStack(spacing: 8) {
                Image(systemName: isStatusError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .foregroundColor(isStatusError ? Color.adaptiveErrorText : Color.adaptiveSuccessText)
                Text(message)
                    .font(.caption.weight(.medium))
                    .foregroundColor(Color.primary)
                Spacer()
                Button(action: clearStatusMessage) {
                    Image(systemName: "xmark")
                        .font(.caption.bold())
                        .foregroundColor(Color.secondary)
                }
                .buttonStyle(.borderless)
            }
            .padding(10)
            .background(isStatusError ? Color.red.opacity(0.12) : Color.green.opacity(0.12))
            .cornerRadius(8)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }
    
    // MARK: - Tab 1: Subjects
    
    private var subjectsTab: some View {
        List {
            Section {
                Button(action: openAddCategory) {
                    Label("Add New Subject", systemImage: "plus.circle.fill")
                        .font(.body.bold())
                        .foregroundColor(.accentColor)
                        .frame(minHeight: 44)
                }
                .accessibilityLabel("Add New Subject")
                .accessibilityIdentifier("studyMaterial.addSubjectButton")
            }
            
            Section(header: Text("Academic Subjects (\(viewModel.allCategories.count))")) {
                ForEach(viewModel.allCategories, id: \.rawValue) { (category: QuizCategory) in
                    HStack(spacing: 12) {
                        Image(systemName: category.iconName)
                            .font(.title3)
                            .foregroundColor(.accentColor)
                            .frame(width: 32, height: 32)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(category.displayName)
                                    .font(.headline)
                                    .foregroundColor(Color.primary)
                                Spacer()
                                if category.isCustom {
                                    Button {
                                        openEditCategory(category)
                                    } label: {
                                        Image(systemName: "pencil")
                                            .font(.caption.bold())
                                            .foregroundColor(.accentColor)
                                            .padding(6)
                                    }
                                    .buttonStyle(.borderless)
                                    .accessibilityLabel("Edit Subject \(category.displayName)")
                                    .accessibilityIdentifier("studyMaterial.editSubjectButton.\(category.rawValue)")
                                    
                                    Button(role: .destructive) {
                                        deleteCategory(category)
                                    } label: {
                                        Image(systemName: "trash")
                                            .font(.caption.bold())
                                            .foregroundColor(Color.adaptiveErrorText)
                                            .padding(6)
                                    }
                                    .buttonStyle(.borderless)
                                    .accessibilityLabel("Delete Subject \(category.displayName)")
                                    .accessibilityIdentifier("studyMaterial.deleteSubjectButton.\(category.rawValue)")
                                    
                                    Text("Custom")
                                        .font(.caption2.bold())
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.purple.opacity(0.15))
                                        .foregroundColor(.purple)
                                        .cornerRadius(4)
                                } else {
                                    Text("Curriculum")
                                        .font(.caption2.bold())
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.15))
                                        .foregroundColor(.blue)
                                        .cornerRadius(4)
                                }
                            }
                            
                            Text(category.localizedDescription)
                                .font(.caption)
                                .foregroundColor(Color.secondary)
                                .lineLimit(2)
                            
                            Text("\(viewModel.questionCount(for: category)) questions")
                                .font(.caption2.weight(.medium))
                                .foregroundColor(.accentColor)
                        }
                    }
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .contain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if category.isCustom {
                            Button(role: .destructive) {
                                deleteCategory(category)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                openEditCategory(category)
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.orange)
                        }
                    }
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
    }
    
    // MARK: - Tab 2: Questions
    
    private var questionsTab: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: openAddQuestion) {
                    Label("Add Question", systemImage: "plus.circle.fill")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 12)
                        .frame(minHeight: 44)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .accessibilityLabel("Add New Question")
                .accessibilityIdentifier("studyMaterial.addQuestionButton")
                
                Spacer()
                
                Picker("Filter", selection: $selectedCategoryFilter) {
                    Text("All Custom").tag("all")
                    ForEach(viewModel.allCategories, id: \.rawValue) { (cat: QuizCategory) in
                        Text(cat.displayName).tag(cat.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityIdentifier("studyMaterial.categoryFilterPicker")
                .frame(minHeight: 44)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            let filteredQuestions = viewModel.customQuestions.filter { q in
                selectedCategoryFilter == "all" || q.category.rawValue == selectedCategoryFilter
            }
            
            if filteredQuestions.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(Color.secondary)
                    Text("No Custom Questions Yet")
                        .font(.headline)
                        .foregroundColor(Color.primary)
                    Text("Create questions manually or import an existing JSON question set.")
                        .font(.subheadline)
                        .foregroundColor(Color.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredQuestions) { question in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(question.category.displayName)
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.15))
                                    .foregroundColor(.blue)
                                    .cornerRadius(4)
                                
                                Text(question.difficulty.displayName)
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.15))
                                    .foregroundColor(.orange)
                                    .cornerRadius(4)
                                
                                Spacer()
                                
                                Button {
                                    openEditQuestion(question)
                                } label: {
                                    Image(systemName: "pencil")
                                        .font(.caption.bold())
                                        .foregroundColor(.accentColor)
                                        .frame(minWidth: 32, minHeight: 32)
                                }
                                .buttonStyle(.borderless)
                                .accessibilityLabel("Edit Question")
                                .accessibilityIdentifier("studyMaterial.editQuestionButton")
                                
                                Button(role: .destructive) {
                                    deleteQuestion(question)
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.caption.bold())
                                        .foregroundColor(Color.adaptiveErrorText)
                                        .frame(minWidth: 32, minHeight: 32)
                                }
                                .buttonStyle(.borderless)
                                .accessibilityLabel("Delete Question")
                                .accessibilityIdentifier("studyMaterial.deleteQuestionButton")
                            }
                            
                            Text(question.prompt)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(Color.primary)
                            
                            Text("Answer: \(question.correctAnswerText)")
                                .font(.caption)
                                .foregroundColor(Color.adaptiveSuccessText)
                            
                            Text(question.explanation)
                                .font(.caption2)
                                .foregroundColor(Color.secondary)
                                .lineLimit(2)
                        }
                        .padding(.vertical, 4)
                        .accessibilityElement(children: .contain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                deleteQuestion(question)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                #if os(iOS)
                .listStyle(.insetGrouped)
                #else
                .listStyle(.inset)
                #endif
            }
        }
    }
    
    // MARK: - Tab 3: Import
    
    private var importTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                // File Import Section
                VStack(alignment: .leading, spacing: 12) {
                    Label("Import Local JSON File", systemImage: "doc.badge.plus")
                        .font(.headline)
                        .foregroundColor(Color.primary)
                    
                    Text("Select a compatible JSON catalog file or an array of multiple-choice questions from your device or iCloud Drive.")
                        .font(.caption)
                        .foregroundColor(Color.secondary)
                    
                    Button(action: openFileImporter) {
                        HStack {
                            Image(systemName: "folder")
                            Text("Browse & Select JSON File")
                        }
                        .font(.body.bold())
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 48)
                        .background(Color.adaptiveCardBackground)
                        .foregroundColor(.accentColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.accentColor.opacity(0.4), lineWidth: 1.5)
                        )
                        .cornerRadius(10)
                    }
                    .accessibilityLabel("Select JSON File to import")
                    .accessibilityIdentifier("studyMaterial.browseFileButton")
                }
                .padding(16)
                .background(Color.adaptiveCardBackground)
                .cornerRadius(12)
                
                // URL Network Import Section
                VStack(alignment: .leading, spacing: 12) {
                    Label("Download from Web URL", systemImage: "network")
                        .font(.headline)
                        .foregroundColor(Color.primary)
                    
                    Text("Enter a direct HTTP or HTTPS URL pointing to a raw JSON question bank.")
                        .font(.caption)
                        .foregroundColor(Color.secondary)
                    
                    TextField("https://example.com/study_questions.json", text: $importURLString)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        #endif
                        .frame(minHeight: 44)
                    
                    Button(action: downloadFromURL) {
                        HStack {
                            if isDownloading {
                                ProgressView()
                                    .padding(.trailing, 4)
                            } else {
                                Image(systemName: "arrow.down.circle.fill")
                            }
                            Text(isDownloading ? "Downloading…" : "Download & Import")
                        }
                        .font(.body.bold())
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 48)
                        .background(importURLString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isDownloading ? Color.gray.opacity(0.3) : Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(importURLString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isDownloading)
                    .accessibilityLabel("Download and import study material from URL")
                }
                .padding(16)
                .background(Color.adaptiveCardBackground)
                .cornerRadius(12)
                
                // Format Guidelines
                VStack(alignment: .leading, spacing: 8) {
                    Text("Supported Schema Format")
                        .font(.caption.bold())
                        .foregroundColor(Color.secondary)
                    Text("The imported JSON may be either a full catalog object (`{\"categories\": [...], \"questions\": [...]}`) or a simple array of standard question objects (`[{ \"prompt\": \"...\", \"options\": [\"A\", \"B\", \"C\", \"D\"], \"correctAnswerIndex\": 0, ... }]`). Invariants are strictly checked: malformed items are rejected transactionally.")
                        .font(.caption2)
                        .foregroundColor(Color.secondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
        }
    }
    
    // MARK: - Actions & Handlers
    
    func deleteCategory(_ category: QuizCategory) {
        do {
            try viewModel.deleteCustomCategory(id: category.rawValue)
            statusMessage = "Category '\(category.displayName)' and its questions were deleted."
            isStatusError = false
        } catch {
            statusMessage = error.localizedDescription
            isStatusError = true
        }
    }
    
    func deleteQuestion(_ question: Question) {
        do {
            try viewModel.deleteCustomQuestion(id: question.id)
            statusMessage = "Question deleted."
            isStatusError = false
        } catch {
            statusMessage = error.localizedDescription
            isStatusError = true
        }
    }
    
    func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let selectedURL = urls.first else { return }
            let shouldStopAccessing = selectedURL.startAccessingSecurityScopedResource()
            defer {
                if shouldStopAccessing {
                    selectedURL.stopAccessingSecurityScopedResource()
                }
            }
            
            do {
                let data = try Data(contentsOf: selectedURL)
                let result = try viewModel.importStudyMaterial(from: data)
                statusMessage = "Imported \(result.categoriesCount) categories and \(result.questionsCount) questions successfully."
                isStatusError = false
            } catch {
                statusMessage = "Import failed: \(error.localizedDescription)"
                isStatusError = true
            }
        case .failure(let error):
            statusMessage = "File selection failed: \(error.localizedDescription)"
            isStatusError = true
        }
    }
    
    func downloadFromURL() {
        let trimmed = importURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            statusMessage = "Please enter a valid HTTP or HTTPS URL."
            isStatusError = true
            return
        }
        
        isDownloading = true
        Task {
            do {
                let result = try await viewModel.importStudyMaterial(from: url)
                await MainActor.run {
                    self.isDownloading = false
                    self.statusMessage = "Successfully downloaded and imported \(result.categoriesCount) categories and \(result.questionsCount) questions."
                    self.isStatusError = false
                    self.importURLString = ""
                }
            } catch {
                await MainActor.run {
                    self.isDownloading = false
                    self.statusMessage = "Remote import failed: \(error.localizedDescription)"
                    self.isStatusError = true
                }
            }
        }
    }
}

// MARK: - Sheet: Add Category
struct AddCategorySheet: View {
    @ObservedObject var viewModel: QuizViewModel
    @Environment(\.dismiss) private var dismiss
    let onCompletion: (Bool, String) -> Void
    
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var selectedIcon: String = "folder.fill"
    @State private var errorMessage: String?
    @State private var showErrorAlert: Bool = false
    
    private let availableIcons = [
        "folder.fill", "book.fill", "graduationcap.fill", "laptopcomputer",
        "atom", "cpu", "network", "shield.fill", "globe", "server.rack"
    ]
    
    init(
        viewModel: QuizViewModel,
        initialName: String = "",
        initialDescription: String = "",
        initialIcon: String = "folder.fill",
        initialErrorMessage: String? = nil,
        onCompletion: @escaping (Bool, String) -> Void
    ) {
        self.viewModel = viewModel
        self._name = State(initialValue: initialName)
        self._description = State(initialValue: initialDescription)
        self._selectedIcon = State(initialValue: initialIcon)
        self._errorMessage = State(initialValue: initialErrorMessage)
        self._showErrorAlert = State(initialValue: initialErrorMessage != nil)
        self.onCompletion = onCompletion
    }
    
    func selectIcon(_ icon: String) {
        selectedIcon = icon
    }
    
    func triggerDismiss() {
        dismiss()
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if let error = errorMessage {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(Color.adaptiveErrorText)
                            Text(error)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(Color.adaptiveErrorText)
                        }
                        .accessibilityIdentifier("studyMaterial.addCategoryErrorBanner")
                    }
                }
                
                Section(header: Text("Subject Details")) {
                    TextField("Subject Name (e.g. Cloud Computing)", text: $name)
                        .accessibilityIdentifier("studyMaterial.newSubjectNameField")
                        .frame(minHeight: 44)
                    TextField("Description (e.g. AWS, GCP, Azure fundamentals)", text: $description)
                        .frame(minHeight: 44)
                }
                
                Section(header: Text("Icon Symbol")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(availableIcons, id: \.self) { icon in
                                Button {
                                    selectIcon(icon)
                                } label: {
                                    Image(systemName: icon)
                                        .font(.title2)
                                        .frame(width: 44, height: 44)
                                        .background(selectedIcon == icon ? Color.accentColor : Color.adaptiveCardBackground)
                                        .foregroundColor(selectedIcon == icon ? .white : Color.primary)
                                        .cornerRadius(10)
                                }
                                .buttonStyle(.borderless)
                                .accessibilityLabel("Icon \(icon)")
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("New Subject")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .alert("Cannot Save Subject", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
                    .accessibilityIdentifier("studyMaterial.addCategoryAlertOKButton")
            } message: {
                Text(errorMessage ?? "")
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: triggerDismiss)
                        .frame(minHeight: 44)
                        .accessibilityIdentifier("studyMaterial.cancelSubjectButton")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: saveCategory)
                        .font(.body.bold())
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityIdentifier("studyMaterial.saveNewSubjectButton")
                        .frame(minHeight: 44)
                }
                #if os(iOS)
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .accessibilityIdentifier("studyMaterial.addCategoryKeyboardDoneButton")
                }
                #endif
            }
        }
    }
    
    func saveCategory() {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else {
            errorMessage = "Subject name cannot be empty."
            showErrorAlert = true
            return
        }
        
        do {
            try viewModel.addCustomCategory(
                name: cleanName,
                iconName: selectedIcon,
                description: description
            )
            onCompletion(true, "Created subject '\(cleanName)'.")
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
}

// MARK: - Sheet: Edit Category
struct EditCategorySheet: View {
    @ObservedObject var viewModel: QuizViewModel
    let category: QuizCategory
    @Environment(\.dismiss) private var dismiss
    let onCompletion: (Bool, String) -> Void
    
    @State private var name: String
    @State private var description: String
    @State private var selectedIcon: String
    @State private var errorMessage: String?
    @State private var showErrorAlert: Bool = false
    
    private let availableIcons = [
        "folder.fill", "book.fill", "graduationcap.fill", "laptopcomputer",
        "atom", "cpu", "network", "shield.fill", "globe", "server.rack"
    ]
    
    init(
        viewModel: QuizViewModel,
        category: QuizCategory,
        initialName: String? = nil,
        initialDescription: String? = nil,
        initialIcon: String? = nil,
        initialErrorMessage: String? = nil,
        onCompletion: @escaping (Bool, String) -> Void
    ) {
        self.viewModel = viewModel
        self.category = category
        self.onCompletion = onCompletion
        _name = State(initialValue: initialName ?? category.displayName)
        _description = State(initialValue: initialDescription ?? category.localizedDescription)
        _selectedIcon = State(initialValue: initialIcon ?? category.iconName)
        _errorMessage = State(initialValue: initialErrorMessage)
        _showErrorAlert = State(initialValue: initialErrorMessage != nil)
    }
    
    func selectIcon(_ icon: String) {
        selectedIcon = icon
    }
    
    func triggerDismiss() {
        dismiss()
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if let error = errorMessage {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(Color.adaptiveErrorText)
                            Text(error)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(Color.adaptiveErrorText)
                        }
                        .accessibilityIdentifier("studyMaterial.editCategoryErrorBanner")
                    }
                }
                
                Section(header: Text("Subject Details")) {
                    TextField("Subject Name", text: $name)
                        .accessibilityIdentifier("studyMaterial.editSubjectNameField")
                        .frame(minHeight: 44)
                    TextField("Description", text: $description)
                        .frame(minHeight: 44)
                }
                
                Section(header: Text("Icon Symbol")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(availableIcons, id: \.self) { icon in
                                Button {
                                    selectIcon(icon)
                                } label: {
                                    Image(systemName: icon)
                                        .font(.title2)
                                        .frame(width: 44, height: 44)
                                        .background(selectedIcon == icon ? Color.accentColor : Color.adaptiveCardBackground)
                                        .foregroundColor(selectedIcon == icon ? .white : Color.primary)
                                        .cornerRadius(10)
                                }
                                .buttonStyle(.borderless)
                                .accessibilityLabel("Icon \(icon)")
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Edit Subject")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .alert("Cannot Save Subject", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
                    .accessibilityIdentifier("studyMaterial.editCategoryAlertOKButton")
            } message: {
                Text(errorMessage ?? "")
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: triggerDismiss)
                        .frame(minHeight: 44)
                        .accessibilityIdentifier("studyMaterial.cancelEditSubjectButton")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: saveCategory)
                        .font(.body.bold())
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityIdentifier("studyMaterial.saveEditSubjectButton")
                        .frame(minHeight: 44)
                }
                #if os(iOS)
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .accessibilityIdentifier("studyMaterial.editCategoryKeyboardDoneButton")
                }
                #endif
            }
        }
    }
    
    func saveCategory() {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else {
            errorMessage = "Subject name cannot be empty."
            showErrorAlert = true
            return
        }
        
        do {
            try viewModel.updateCustomCategory(
                id: category.rawValue,
                displayName: cleanName,
                iconName: selectedIcon,
                description: description.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            onCompletion(true, "Subject '\(cleanName)' updated successfully.")
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
}

// MARK: - Sheet: Question Editor
struct QuestionEditorSheet: View {
    @ObservedObject var viewModel: QuizViewModel
    let editingQuestion: Question?
    @Environment(\.dismiss) private var dismiss
    let onCompletion: (Bool, String) -> Void
    
    @State private var prompt: String = ""
    @State private var option0: String = ""
    @State private var option1: String = ""
    @State private var option2: String = ""
    @State private var option3: String = ""
    @State private var correctAnswerIndex: Int = 0
    @State private var explanation: String = ""
    @State private var selectedCategoryId: String = ""
    @State private var difficulty: Difficulty = .medium
    @State private var errorMessage: String?
    @State private var showErrorAlert: Bool = false
    
    init(
        viewModel: QuizViewModel,
        editingQuestion: Question?,
        initialCategoryId: String? = nil,
        initialPrompt: String? = nil,
        initialOption0: String? = nil,
        initialOption1: String? = nil,
        initialOption2: String? = nil,
        initialOption3: String? = nil,
        initialCorrectIndex: Int? = nil,
        initialExplanation: String? = nil,
        initialDifficulty: Difficulty? = nil,
        initialErrorMessage: String? = nil,
        onCompletion: @escaping (Bool, String) -> Void
    ) {
        self.viewModel = viewModel
        self.editingQuestion = editingQuestion
        self.onCompletion = onCompletion
        
        let initialCat = initialCategoryId ?? editingQuestion?.category.rawValue ?? viewModel.allCategories.first(where: { $0.isCustom })?.rawValue ?? viewModel.allCategories.first?.rawValue ?? ""
        _selectedCategoryId = State(initialValue: initialCat)
        _prompt = State(initialValue: initialPrompt ?? editingQuestion?.prompt ?? "")
        _option0 = State(initialValue: initialOption0 ?? (editingQuestion?.options.indices.contains(0) == true ? editingQuestion!.options[0] : ""))
        _option1 = State(initialValue: initialOption1 ?? (editingQuestion?.options.indices.contains(1) == true ? editingQuestion!.options[1] : ""))
        _option2 = State(initialValue: initialOption2 ?? (editingQuestion?.options.indices.contains(2) == true ? editingQuestion!.options[2] : ""))
        _option3 = State(initialValue: initialOption3 ?? (editingQuestion?.options.indices.contains(3) == true ? editingQuestion!.options[3] : ""))
        _correctAnswerIndex = State(initialValue: initialCorrectIndex ?? editingQuestion?.correctAnswerIndex ?? 0)
        _explanation = State(initialValue: initialExplanation ?? editingQuestion?.explanation ?? "")
        _difficulty = State(initialValue: initialDifficulty ?? editingQuestion?.difficulty ?? .medium)
        _errorMessage = State(initialValue: initialErrorMessage)
        _showErrorAlert = State(initialValue: initialErrorMessage != nil)
    }
    
    func selectCorrectIndex(_ index: Int) {
        correctAnswerIndex = index
    }
    
    func triggerDismiss() {
        dismiss()
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if let error = errorMessage {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(Color.adaptiveErrorText)
                            Text(error)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(Color.adaptiveErrorText)
                        }
                        .accessibilityIdentifier("studyMaterial.questionEditorErrorBanner")
                    }
                }
                
                Section(header: Text("Classification")) {
                    Picker("Subject", selection: $selectedCategoryId) {
                        ForEach(viewModel.allCategories, id: \.rawValue) { (cat: QuizCategory) in
                            Text(cat.displayName).tag(cat.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityIdentifier("studyMaterial.questionSubjectPicker")
                    .frame(minHeight: 44)
                    
                    Picker("Difficulty", selection: $difficulty) {
                        ForEach(Difficulty.allCases, id: \.self) { diff in
                            Text(diff.displayName).tag(diff)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityIdentifier("studyMaterial.questionDifficultyPicker")
                    .frame(minHeight: 44)
                }
                
                Section(header: Text("Question Prompt")) {
                    TextField("Enter question prompt…", text: $prompt)
                        .accessibilityIdentifier("studyMaterial.questionPromptField")
                        .frame(minHeight: 44)
                }
                
                Section(header: Text("Multiple Choice Options (Select Correct)"), footer: Text("Mark the single correct choice with the radio button.")) {
                    optionRow(index: 0, text: $option0)
                    optionRow(index: 1, text: $option1)
                    optionRow(index: 2, text: $option2)
                    optionRow(index: 3, text: $option3)
                }
                
                Section(header: Text("Pedagogical Explanation (Required)")) {
                    TextField("Explain why the correct answer is right…", text: $explanation)
                        .accessibilityIdentifier("studyMaterial.questionExplanationField")
                        .frame(minHeight: 44)
                }
            }
            .navigationTitle(editingQuestion == nil ? "New Question" : "Edit Question")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .alert("Cannot Save Question", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
                    .accessibilityIdentifier("studyMaterial.questionAlertOKButton")
            } message: {
                Text(errorMessage ?? "")
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: triggerDismiss)
                        .frame(minHeight: 44)
                        .accessibilityIdentifier("studyMaterial.cancelQuestionButton")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: saveQuestion)
                        .font(.body.bold())
                        .accessibilityIdentifier("studyMaterial.saveQuestionButton")
                        .frame(minHeight: 44)
                }
                #if os(iOS)
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .accessibilityIdentifier("studyMaterial.keyboardDoneButton")
                }
                #endif
            }
        }
    }
    
    func optionRow(index: Int, text: Binding<String>) -> some View {
        HStack(spacing: 12) {
            Button {
                selectCorrectIndex(index)
            } label: {
                Image(systemName: correctAnswerIndex == index ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(correctAnswerIndex == index ? Color.adaptiveSuccessText : Color.gray)
                    .font(.title3)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Mark option \(index + 1) as correct")
            .accessibilityIdentifier("studyMaterial.correctOptionRadio.\(index)")
            
            TextField("Option \(index + 1)", text: text)
                .accessibilityIdentifier("studyMaterial.questionOption.\(index)")
                .frame(minHeight: 44)
        }
    }
    
    func saveQuestion() {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else {
            presentError("Please enter a question prompt.")
            return
        }
        
        guard let cat = viewModel.allCategories.first(where: { $0.rawValue == selectedCategoryId }) else {
            presentError("Please select a valid subject.")
            return
        }
        
        let trimmedOption0 = option0.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedOption1 = option1.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedOption2 = option2.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedOption3 = option3.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedOption0.isEmpty && !trimmedOption1.isEmpty && !trimmedOption2.isEmpty && !trimmedOption3.isEmpty else {
            presentError("Please provide text for all 4 multiple-choice options.")
            return
        }
        
        let uniqueOptions = Set([trimmedOption0, trimmedOption1, trimmedOption2, trimmedOption3])
        guard uniqueOptions.count == 4 else {
            presentError("All 4 options must be unique to prevent ambiguity.")
            return
        }
        
        let trimmedExplanation = explanation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedExplanation.isEmpty else {
            presentError("Please provide a pedagogical explanation for feedback.")
            return
        }
        
        let options = [trimmedOption0, trimmedOption1, trimmedOption2, trimmedOption3]
        
        do {
            if let editing = editingQuestion {
                try viewModel.updateCustomQuestion(
                    id: editing.id,
                    prompt: trimmedPrompt,
                    options: options,
                    correctAnswerIndex: correctAnswerIndex,
                    explanation: trimmedExplanation,
                    category: cat,
                    difficulty: difficulty
                )
                onCompletion(true, "Question updated.")
            } else {
                try viewModel.addCustomQuestion(
                    prompt: trimmedPrompt,
                    options: options,
                    correctAnswerIndex: correctAnswerIndex,
                    explanation: trimmedExplanation,
                    category: cat,
                    difficulty: difficulty
                )
                onCompletion(true, "Question created successfully.")
            }
            dismiss()
        } catch {
            presentError(error.localizedDescription)
        }
    }
    
    private func presentError(_ message: String) {
        self.errorMessage = message
        self.showErrorAlert = true
    }
}
