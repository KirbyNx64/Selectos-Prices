class OfferCampaign {
  final String title;
  final String url;
  final String imageUrl;

  const OfferCampaign({
    required this.title,
    required this.url,
    required this.imageUrl,
  });
}

class OfferHomeContent {
  final List<OfferCampaign> banners;
  final List<OfferCampaign> campaigns;

  const OfferHomeContent({required this.banners, required this.campaigns});
}
