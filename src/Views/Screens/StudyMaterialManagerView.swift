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
    
    public init(viewModel: QuizViewModel) {
        self.viewModel = viewModel
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
                    Button("Done") {
                        dismiss()
                    }
                    .font(.body.bold())
                    .frame(minHeight: 44)
                    .accessibilityIdentifier("studyMaterial.doneButton")
                }
            }
            .sheet(isPresented: $showAddCategorySheet) {
                AddCategorySheet(viewModel: viewModel) { success, msg in
                    self.isStatusError = !success
                    self.statusMessage = msg
                }
            }
            .sheet(item: $categoryToEdit) { category in
                EditCategorySheet(viewModel: viewModel, category: category) { success, msg in
                    self.isStatusError = !success
                    self.statusMessage = msg
                    self.categoryToEdit = nil
                }
            }
            .sheet(isPresented: $showQuestionEditorSheet) {
                QuestionEditorSheet(
                    viewModel: viewModel,
                    editingQuestion: questionToEdit
                ) { success, msg in
                    self.isStatusError = !success
                    self.statusMessage = msg
                    self.questionToEdit = nil
                }
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result: result)
            }
            .onAppear {
                if let warning = viewModel.lastLoadWarning, statusMessage == nil {
                    self.statusMessage = warning
                    self.isStatusError = warning.contains("CRITICAL")
                }
            }
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
                Button {
                    statusMessage = nil
                } label: {
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
                Button {
                    showAddCategorySheet = true
                } label: {
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
                                        categoryToEdit = category
                                        showEditCategorySheet = true
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
                                categoryToEdit = category
                                showEditCategorySheet = true
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
                Button {
                    questionToEdit = nil
                    showQuestionEditorSheet = true
                } label: {
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
                                    questionToEdit = question
                                    showQuestionEditorSheet = true
                                } label: {
                                    Image(systemName: "pencil")
                                        .font(.caption.bold())
                                        .foregroundColor(.accentColor)
                                        .frame(minWidth: 32, minHeight: 32)
                                }
                                .buttonStyle(.borderless)
                                .accessibilityLabel("Edit Question")
                                
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
                    
                    Button {
                        showFileImporter = true
                    } label: {
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
                    
                    Button {
                        downloadFromURL()
                    } label: {
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
    
    private func deleteCategory(_ category: QuizCategory) {
        do {
            try viewModel.deleteCustomCategory(id: category.rawValue)
            statusMessage = "Category '\(category.displayName)' and its questions were deleted."
            isStatusError = false
        } catch {
            statusMessage = error.localizedDescription
            isStatusError = true
        }
    }
    
    private func deleteQuestion(_ question: Question) {
        do {
            try viewModel.deleteCustomQuestion(id: question.id)
            statusMessage = "Question deleted."
            isStatusError = false
        } catch {
            statusMessage = error.localizedDescription
            isStatusError = true
        }
    }
    
    private func handleFileImport(result: Result<[URL], Error>) {
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
    
    private func downloadFromURL() {
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
    
    private let availableIcons = [
        "folder.fill", "book.fill", "graduationcap.fill", "laptopcomputer",
        "atom", "cpu", "network", "shield.fill", "globe", "server.rack"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
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
                                    selectedIcon = icon
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
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(Color.adaptiveErrorText)
                    }
                }
            }
            .navigationTitle("New Subject")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .frame(minHeight: 44)
                        .accessibilityIdentifier("studyMaterial.cancelSubjectButton")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveCategory() }
                        .font(.body.bold())
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityIdentifier("studyMaterial.saveNewSubjectButton")
                        .frame(minHeight: 44)
                }
            }
        }
    }
    
    private func saveCategory() {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else {
            errorMessage = "Subject name cannot be empty."
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
    
    private let availableIcons = [
        "folder.fill", "book.fill", "graduationcap.fill", "laptopcomputer",
        "atom", "cpu", "network", "shield.fill", "globe", "server.rack"
    ]
    
    init(
        viewModel: QuizViewModel,
        category: QuizCategory,
        onCompletion: @escaping (Bool, String) -> Void
    ) {
        self.viewModel = viewModel
        self.category = category
        self.onCompletion = onCompletion
        _name = State(initialValue: category.displayName)
        _description = State(initialValue: category.localizedDescription)
        _selectedIcon = State(initialValue: category.iconName)
    }
    
    var body: some View {
        NavigationStack {
            Form {
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
                                    selectedIcon = icon
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
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(Color.adaptiveErrorText)
                    }
                }
            }
            .navigationTitle("Edit Subject")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .frame(minHeight: 44)
                        .accessibilityIdentifier("studyMaterial.cancelEditSubjectButton")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveCategory() }
                        .font(.body.bold())
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityIdentifier("studyMaterial.saveEditSubjectButton")
                        .frame(minHeight: 44)
                }
            }
        }
    }
    
    private func saveCategory() {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else {
            errorMessage = "Subject name cannot be empty."
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
    
    init(
        viewModel: QuizViewModel,
        editingQuestion: Question?,
        onCompletion: @escaping (Bool, String) -> Void
    ) {
        self.viewModel = viewModel
        self.editingQuestion = editingQuestion
        self.onCompletion = onCompletion
        
        let initialCat = editingQuestion?.category.rawValue ?? viewModel.allCategories.first(where: { $0.isCustom })?.rawValue ?? viewModel.allCategories.first?.rawValue ?? ""
        _selectedCategoryId = State(initialValue: initialCat)
        if let q = editingQuestion {
            _prompt = State(initialValue: q.prompt)
            _option0 = State(initialValue: q.options.indices.contains(0) ? q.options[0] : "")
            _option1 = State(initialValue: q.options.indices.contains(1) ? q.options[1] : "")
            _option2 = State(initialValue: q.options.indices.contains(2) ? q.options[2] : "")
            _option3 = State(initialValue: q.options.indices.contains(3) ? q.options[3] : "")
            _correctAnswerIndex = State(initialValue: q.correctAnswerIndex)
            _explanation = State(initialValue: q.explanation)
            _difficulty = State(initialValue: q.difficulty)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
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
                
                Section(header: Text("Pedagogical Explanation")) {
                    TextField("Explain why the correct answer is right…", text: $explanation)
                        .accessibilityIdentifier("studyMaterial.questionExplanationField")
                        .frame(minHeight: 44)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(Color.adaptiveErrorText)
                    }
                }
            }
            .navigationTitle(editingQuestion == nil ? "New Question" : "Edit Question")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .frame(minHeight: 44)
                        .accessibilityIdentifier("studyMaterial.cancelQuestionButton")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveQuestion() }
                        .font(.body.bold())
                        .accessibilityIdentifier("studyMaterial.saveQuestionButton")
                        .frame(minHeight: 44)
                }
            }
        }
    }
    
    private func optionRow(index: Int, text: Binding<String>) -> some View {
        HStack(spacing: 12) {
            Button {
                correctAnswerIndex = index
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
    
    private func saveQuestion() {
        guard let cat = viewModel.allCategories.first(where: { $0.rawValue == selectedCategoryId }) else {
            errorMessage = "Please select a valid subject."
            return
        }
        
        let options = [option0, option1, option2, option3]
        
        do {
            if let editing = editingQuestion {
                try viewModel.updateCustomQuestion(
                    id: editing.id,
                    prompt: prompt,
                    options: options,
                    correctAnswerIndex: correctAnswerIndex,
                    explanation: explanation,
                    category: cat,
                    difficulty: difficulty
                )
                onCompletion(true, "Question updated.")
            } else {
                try viewModel.addCustomQuestion(
                    prompt: prompt,
                    options: options,
                    correctAnswerIndex: correctAnswerIndex,
                    explanation: explanation,
                    category: cat,
                    difficulty: difficulty
                )
                onCompletion(true, "Question created successfully.")
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
