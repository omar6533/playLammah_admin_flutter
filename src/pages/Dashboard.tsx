import { useEffect, useState } from 'react';
import { Folder, FolderOpen, FileQuestion, CheckCircle, Gamepad2, Users } from 'lucide-react';
import { statsApi, questionsApi, Question } from '../lib/api';
import Badge from '../components/Badge';

interface Stats {
  totalMainCategories: number;
  totalSubCategories: number;
  totalQuestions: number;
  activeQuestions: number;
  totalGames: number;
  totalUsers: number;
}

export default function Dashboard() {
  const [stats, setStats] = useState<Stats>({
    totalMainCategories: 0,
    totalSubCategories: 0,
    totalQuestions: 0,
    activeQuestions: 0,
    totalGames: 0,
    totalUsers: 0,
  });
  const [latestQuestions, setLatestQuestions] = useState<Question[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadDashboardData();
  }, []);

  const loadDashboardData = async () => {
    try {
      const [statsData, questionsData] = await Promise.all([
        statsApi.getDashboardStats(),
        questionsApi.getAll({ status: 'active' }),
      ]);
      setStats(statsData);
      setLatestQuestions(questionsData.slice(0, 10));
    } catch (error) {
      console.error('Error loading dashboard data:', error);
    } finally {
      setLoading(false);
    }
  };

  const statCards = [
    {
      title: 'Main Categories',
      value: stats.totalMainCategories,
      icon: Folder,
      color: 'bg-blue-500',
    },
    {
      title: 'Sub Categories',
      value: stats.totalSubCategories,
      icon: FolderOpen,
      color: 'bg-indigo-500',
    },
    {
      title: 'Total Questions',
      value: stats.totalQuestions,
      icon: FileQuestion,
      color: 'bg-green-500',
    },
    {
      title: 'Active Questions',
      value: stats.activeQuestions,
      icon: CheckCircle,
      color: 'bg-teal-500',
    },
    {
      title: 'Total Games Played',
      value: stats.totalGames,
      icon: Gamepad2,
      color: 'bg-orange-500',
    },
    {
      title: 'Total Users',
      value: stats.totalUsers,
      icon: Users,
      color: 'bg-rose-500',
    },
  ];

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-gray-500">Loading dashboard data...</div>
      </div>
    );
  }

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Dashboard</h1>
        <p className="text-gray-600 mt-1">Overview of your quiz game platform</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-6">
        {statCards.map((card, index) => {
          const Icon = card.icon;
          return (
            <div key={index} className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">{card.title}</p>
                  <p className="text-3xl font-bold text-gray-900 mt-2">{card.value}</p>
                </div>
                <div className={`${card.color} w-14 h-14 rounded-xl flex items-center justify-center`}>
                  <Icon className="w-7 h-7 text-white" />
                </div>
              </div>
            </div>
          );
        })}
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-gray-200">
        <div className="p-6 border-b border-gray-200">
          <h2 className="text-xl font-bold text-gray-900">Latest Questions</h2>
          <p className="text-sm text-gray-600 mt-1">Recently created quiz questions</p>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="text-left px-6 py-4 text-xs font-semibold text-gray-600 uppercase tracking-wider">
                  Question
                </th>
                <th className="text-left px-6 py-4 text-xs font-semibold text-gray-600 uppercase tracking-wider">
                  Category
                </th>
                <th className="text-left px-6 py-4 text-xs font-semibold text-gray-600 uppercase tracking-wider">
                  Status
                </th>
                <th className="text-left px-6 py-4 text-xs font-semibold text-gray-600 uppercase tracking-wider">
                  Created At
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {latestQuestions.length === 0 ? (
                <tr>
                  <td colSpan={4} className="px-6 py-12 text-center text-gray-500">
                    No questions yet. Create your first question to get started.
                  </td>
                </tr>
              ) : (
                latestQuestions.map((question) => (
                  <tr key={question.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4">
                      <p className="text-sm text-gray-900 font-medium line-clamp-2" dir="rtl">
                        {question.question_text_ar}
                      </p>
                    </td>
                    <td className="px-6 py-4">
                      <span className="text-sm text-gray-700" dir="rtl">
                        {question.sub_categories?.name_ar || 'N/A'}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <Badge variant={question.status === 'active' ? 'success' : question.status === 'draft' ? 'default' : 'error'}>
                        {question.status.charAt(0).toUpperCase() + question.status.slice(1)}
                      </Badge>
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-600">
                      {formatDate(question.created_at)}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
