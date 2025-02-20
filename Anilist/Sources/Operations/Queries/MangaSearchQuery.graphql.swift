// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class MangaSearchQuery: GraphQLQuery {
  public static let operationName: String = "MangaSearchQuery"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query MangaSearchQuery($page: Int, $search: String) { Page(page: $page) { __typename media(search: $search) { __typename id title { __typename romaji english native } coverImage { __typename large } } } }"#
    ))

  public var page: GraphQLNullable<Int>
  public var search: GraphQLNullable<String>

  public init(
    page: GraphQLNullable<Int>,
    search: GraphQLNullable<String>
  ) {
    self.page = page
    self.search = search
  }

  public var __variables: Variables? { [
    "page": page,
    "search": search
  ] }

  public struct Data: Anilist.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { Anilist.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("Page", Page?.self, arguments: ["page": .variable("page")]),
    ] }

    public var page: Page? { __data["Page"] }

    /// Page
    ///
    /// Parent Type: `Page`
    public struct Page: Anilist.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { Anilist.Objects.Page }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("media", [Medium?]?.self, arguments: ["search": .variable("search")]),
      ] }

      public var media: [Medium?]? { __data["media"] }

      /// Page.Medium
      ///
      /// Parent Type: `Media`
      public struct Medium: Anilist.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { Anilist.Objects.Media }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", Int.self),
          .field("title", Title?.self),
          .field("coverImage", CoverImage?.self),
        ] }

        /// The id of the media
        public var id: Int { __data["id"] }
        /// The official titles of the media in various languages
        public var title: Title? { __data["title"] }
        /// The cover images of the media
        public var coverImage: CoverImage? { __data["coverImage"] }

        /// Page.Medium.Title
        ///
        /// Parent Type: `MediaTitle`
        public struct Title: Anilist.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { Anilist.Objects.MediaTitle }
          public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("romaji", String?.self),
            .field("english", String?.self),
            .field("native", String?.self),
          ] }

          /// The romanization of the native language title
          public var romaji: String? { __data["romaji"] }
          /// The official english title
          public var english: String? { __data["english"] }
          /// Official title in it's native language
          public var native: String? { __data["native"] }
        }

        /// Page.Medium.CoverImage
        ///
        /// Parent Type: `MediaCoverImage`
        public struct CoverImage: Anilist.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { Anilist.Objects.MediaCoverImage }
          public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("large", String?.self),
          ] }

          /// The cover image url of the media at a large size
          public var large: String? { __data["large"] }
        }
      }
    }
  }
}
