//
//  TagView.swift
//  FlippingApp
//
//  Created by Bronson Mullens on 9/29/23.
//

import SwiftUI
import SwiftData

struct TagView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tags: [Tag]

    @Binding var isPresented: Bool
    @Binding var tag: Tag?

    @State private var tagText: String = ""

    var body: some View {
        VStack {
            HStack {
                Button {
                    self.isPresented.toggle()
                } label: {
                    Text("Cancel")
                }

                Spacer()
            }
            .padding()

            HStack {
                TextField("", text: $tagText, prompt: Text("Add a new tag here"))
                    .textFieldStyle(.roundedBorder)

                Button {
                    let newTag = Tag(title: tagText, id: UUID().uuidString)
                    modelContext.insert(newTag)
                    log.info("Created a new tag: \(newTag.title)")
                } label: {
                    Image(systemName: "plus")
                        .resizable()
                        .frame(width: 32, height: 32)
                }
                .disabled(tagText.isEmpty)
            }
            .padding(.horizontal)

            List(tags) { tag in
                HStack {
                    Text("\(tag.title)")
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    log.info("Set tag to: \(tag.title)")
                    self.tag = tag
                    self.isPresented.toggle()
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        modelContext.delete(tag)
                        log.info("Deleted \(tag.title)")
                        do {
                            try modelContext.save()
                        } catch {
                            log.error("Could not save modelContext")
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }

            Spacer()
        }
    }
}
